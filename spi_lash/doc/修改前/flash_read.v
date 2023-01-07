   `include "param.v"
    module flash_read (
        input                  clk       ,
        input                  rst_n     ,
        input                  rden      ,
        input                  rdid      ,
        output   reg           rddone    ,   
        output   reg   [7:0]   rddata    ,
        output   reg           rddata_vld, 

        input                  done      ,
        input          [7:0]   dout      ,
        output   reg           req       ,
        output   reg   [7:0]   din       ,
        output   reg           finish    

    );
    localparam  RD_IDLE   = 7'b000_0001,//1
                RDID_CMD  = 7'b000_0010,//2
                RDID_DATA = 7'b000_0100,//4
                RDDA_CMD  = 7'b000_1000,//8
                RDDA_ADDR = 7'b001_0000,//16 
                RDDA_DATA = 7'b010_0000,//32
                RD_DONE   = 7'b100_0000;//64

    //信号定义
        reg   [6:0]  state_c    ;
        reg   [6:0]  state_n    ;
        reg   [5:0]  byte_cnt   ;
        reg   [5:0]  BYTE_CNT   ;
        reg          byte_done  ;
        reg  [20:0]  delay_cnt  ;
        reg          delay_done ;
        reg          req_en     ;
    
    //状态机
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                state_c<= RD_IDLE;
            else
                state_c<= state_n;
        end 

        always@(*)begin
            case(state_c)
                RD_IDLE  :begin
                            if(rdid)
                                state_n = RDID_CMD ;
                            else if(rden)
                                state_n = RDDA_CMD ;
                            else
                                state_n = state_c;
                          end
                RDID_CMD :begin
                            if(byte_done)
                                state_n = RDID_DATA;
                            else
                                state_n = state_c;
                          end
                RDID_DATA:begin
                            if(byte_done)
                                state_n = RD_DONE;
                            else
                                state_n = state_c;
                          end
                RDDA_CMD :begin
                            if(byte_done)
                                state_n = RDDA_ADDR;
                            else
                                state_n = state_c;
                          end
                RDDA_ADDR:begin
                            if(byte_done)
                                state_n = RDDA_DATA;
                            else
                                state_n = state_c;
                          end
                RDDA_DATA:begin
                            if(byte_done)
                                state_n = RD_DONE  ;
                            else
                                state_n = state_c;
                          end
                RD_DONE  :begin
                            if(delay_done)
                                state_n = RD_IDLE ;
                            else
                                state_n = state_c;
                          end       
                default : state_n = RD_IDLE;
            endcase
        end

    //BYTE_CNT
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                BYTE_CNT <= `CMD_BYTE;
            else if(rden |rdid |((state_c ==RDID_DATA)|(state_c ==RDDA_DATA))&byte_done )
                BYTE_CNT <= `CMD_BYTE;
            else if((state_c ==RDID_CMD)&byte_done )
                BYTE_CNT <= `RDID_BYTE;
            else if((state_c ==RDDA_CMD)&byte_done)
                BYTE_CNT <= `ADDR_BYTE;
            else if((state_c ==RDDA_ADDR)&byte_done)
                BYTE_CNT <= `DATA_BYTE;
        end
    
    //byte_cnt
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                byte_cnt <= 0;
            else if((byte_cnt== BYTE_CNT - 1)&done) 
                byte_cnt <= 0;
            else if(done)
                byte_cnt <=  byte_cnt + 1'b1;
        end

    //byte_done
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                byte_done<= 0;
            else if((byte_cnt== BYTE_CNT - 1)&done)
                byte_done<= 1'b1;
            else
                byte_done<= 1'b0;
        end
    // delay_cnt
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                delay_cnt <= 0;
            else if(delay_cnt== `DELAY_5MS -1) 
                delay_cnt <= 0;
            else if(state_n == RD_DONE)
                delay_cnt <=  delay_cnt + 1'b1;
        end
    //delay_done
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                delay_done<= 0;
            else if(delay_cnt== `DELAY_5MS -1)
                delay_done<= 1'b1;
            else
                delay_done<= 1'b0;
        end
    //din
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                din<= 8'h00;
            else if(rden)
                din<= `CMD_READ;
            else if(rdid)
                din<= `CMD_RDID;
            else if((state_c ==RDID_CMD|state_c ==RDDA_ADDR)&byte_done)
                din<=  8'h00;
            else if(state_c ==RDDA_CMD &byte_done)
                din <= `ADDRESS1;
            else if(state_c ==RDDA_ADDR & byte_cnt ==0& done)
                din <= `ADDRESS2;
            else if(state_c ==RDDA_ADDR & byte_cnt ==1& done)
                din <= `ADDRESS3;
        end
              
    //req_en
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                req_en<= 0;
            else if((((state_c ==RDDA_DATA )&(byte_cnt< BYTE_CNT - 1))|((state_c !=RDDA_DATA)&(state_c !=RD_IDLE)))& done)
                req_en<= 1'b1;
            else
                req_en<= 1'b0;
        end
    //req
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                req<= 0;
            else if(rden|req_en|rdid)
                req<= 1'b1;
            else
                req<= 1'b0;
        end
    //finish
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                finish<= 0;
            else if((state_c ==RDDA_DATA | state_c ==RDID_DATA)&byte_done)
                finish<= 1'b1;
            else
                finish<= 1'b0;
        end
    //rddata
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                rddata<= 0;
            else if((state_c ==RDDA_DATA | state_c ==RDID_DATA )& done)
                rddata<= dout;
        end
    //rddata_vld
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                rddata_vld<= 0;
            else if(state_c ==RDDA_DATA & done)
                rddata_vld<= 1'b1;
            else
                rddata_vld<= 1'b0;
        end
    //rddone
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                rddone<= 0;
            else if(delay_done)
                rddone<= 1'b1;
            else
                rddone<= 1'b0;
        end

    endmodule //flash_read
