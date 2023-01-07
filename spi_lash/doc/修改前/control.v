    `include "param.v"
    module control(
        input                 clk       ,//时钟信号
        input                 rst_n     ,//复位信号
        output       [7:0]    rddata    ,
        output                rddata_vld,
        output                rddone    ,

        output                spi_sclk  ,
        input                 spi_miso  ,
        output                spi_mosi  ,
        output                spi_cs                              
    );  
    //参数定义
        localparam  IDLE  = 4'b0001,
                    WRITE = 4'b0010,
                    READ  = 4'b0100,
                    DONE  = 4'b1000;
    //信号定义

        wire            wrready   ;
        wire            wrdone    ;
        wire    [1:0]   fail      ;
        wire            wreq      ;
        wire    [7:0]   wdin      ;
        wire            wfinish   ;
        wire            rreq      ;
        reg             rreq_r    ;
        wire    [7:0]   rdin      ;
        wire            rfinish   ;
        wire            done      ;
        wire    [7:0]   dout      ;

        reg             wren      ;
        reg             rden      ;
        reg             rdid      ;
        wire            req       ;
        reg     [7:0]   din       ;
        wire            finish    ;
        reg             data_en   ;
        reg     [7:0]   data      ; 
        reg             data_vld  ;
        reg     [3:0]   state_c   ;
        reg     [3:0]   state_n   ;        

        reg     [5:0]   byte_cnt  ;
        reg             byte_done ;
        reg     [20:0]  delay_cnt ;
        reg             delay_done;
    //模块例化
        flash_write u_write(
            /* input                  */.clk     (clk     ),//时钟信号
            /* input                  */.rst_n   (rst_n   ),//复位信号
            /* input                  */.wren    (wren    ),
            /* input          [7:0]   */.data    (data    ),
            /* input                  */.data_vld(data_vld),
            /* output   reg   [1:0]   */.fail    (fail    ),
            /* output   reg           */.wrready (wrready ),
            /* output   reg           */.wrdone  (wrdone  ),

            /* input                  */.done    (done     ),
            /* input          [7:0]   */.dout    (dout     ),
            /* output   reg           */.req     (wreq     ),
            /* output   reg   [7:0]   */.din     (wdin     ),
            /* output   reg           */.finish  (wfinish  )
            
        );
        flash_read u_read(
               /* input                  */.clk       (clk       ),//时钟信号
               /* input                  */.rst_n     (rst_n     ),//复位信号
               /* input                  */.rden      (rden      ),
               /* input                  */.rdid      (rdid      ),
               /* output          [7:0]  */.rddata    (rddata    ),
               /* output                 */.rddata_vld(rddata_vld),
               /* output   reg           */.rddone    (rddone    ),
    
               /* input                  */.done      (done      ),
               /* input          [7:0]   */.dout      (dout      ),
               /* output   reg           */.req       (rreq      ),
               /* output   reg   [7:0]   */.din       (rdin      ),
               /* output   reg           */.finish    (rfinish   )

        );
        spi_master u_spi (
            /* input                  */.clk     (clk     ),//时钟信号
            /* input                  */.rst_n   (rst_n   ),//复位信号
            /* input                  */.req     (req     ),
            /* input         [7:0]    */.din     (din     ),
            /* input                  */.finish  (finish  ),
            /* output   reg           */.done    (done    ),
            /* output   reg  [7:0]    */.dout    (dout    ),

            /* output   reg           */.spi_sclk(spi_sclk),
            /* input                  */.spi_miso(spi_miso),
            /* output   reg           */.spi_mosi(spi_mosi),
            /* output   reg           */.spi_cs  (spi_cs  ) 

        );

        //============= flash clk ============================
            reg    fls_clk_en;
            // always@(posedge sysclk or negedge reset_n)begin
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    fls_clk_en <= 1'b1;
                else
                    fls_clk_en <= 1'b0;   
            end
            //FPGA FLASH clk
            USRMCLK USRMCLK_inst(
                .USRMCLKI (spi_sclk ),
                .USRMCLKTS(fls_clk_en)
            );
    
    //信号处理
        //状态机
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    state_c<= IDLE;
                else
                    state_c<= state_n ;
            end
            always@(*)begin
                case(state_c)
                    IDLE :begin
                            if(delay_done)
                                state_n = WRITE;
                            else
                                state_n = state_c;
                          end
                    WRITE:begin
                            if(fail[1])
                                state_n = READ ;
                            else if(fail[0])
                                state_n = IDLE ;
                            else
                                state_n = state_c;
                          end
                    READ :begin
                            if(rddone)
                                state_n = DONE ;
                            else
                                state_n = state_c;
                          end
                    DONE :begin
                            if(delay_done)
                                state_n = IDLE;
                            else
                                state_n = state_c;
                          end
                    default : state_n<= IDLE;
                endcase
            end
        //delay_cnt 
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    delay_cnt <= 0;
                else if(delay_cnt== `DELAY_5MS - 1) 
                    delay_cnt <= 0;
                else if(state_n == IDLE | state_n== DONE)
                    delay_cnt <=  delay_cnt + 1'b1;
            end
        //delay_done
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    delay_done <= 0;
                else if(delay_cnt== `DELAY_5MS - 1)
                    delay_done <= 1'b1;
                else
                    delay_done <= 1'b0;
            end
        //wren
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    wren <= 0;
                else if(state_c == IDLE &delay_done)
                    wren <= 1'b1;
                else
                    wren <= 1'b0;
            end
        //data_en
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    data_en<= 0;
                else if(wrready)
                    data_en<= 1'b1;
                else
                    data_en<= 1'b0;
            end
        //data_vld
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    data_vld<= 0;
                else if(data_en)
                    data_vld<= 1'b1;
                else
                    data_vld<= 1'b0;
            end
        //data
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    data<= 0;
                else if(wrready)
                    data<= byte_cnt + 4 ;//+ 1'b1
            end
        //byte_cnt
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    byte_cnt <= 0;
                else if((byte_cnt== `DATA_BYTE -1)&wrready) 
                    byte_cnt <= 0;
                else if(wrready)
                    byte_cnt <=  byte_cnt + 1'b1;
            end
        //byte_done
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    byte_done<= 0;
                else if((byte_cnt== `DATA_BYTE -1)&wrready)
                    byte_done<= 1'b1;
                else
                    byte_done<= 1'b0;
            end
        //rden
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    rden<= 0;
                else if(wrdone)
                    rden<= 1'b1;
                else
                    rden<= 1'b0;
            end
        //rreq_r
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    rreq_r<= 0;
                else
                    rreq_r<= rreq;
            end
        //req/din/finish
            assign req   = wreq    | rreq_r   ;
            assign finish= wfinish | rfinish;
        //din
            always@(posedge clk or negedge rst_n)begin
                if(!rst_n)
                    din <= 0;
                else if(state_n == WRITE)
                    din <= wdin;
                else if(state_n == READ)
                    din <= rdin;
            end
    endmodule