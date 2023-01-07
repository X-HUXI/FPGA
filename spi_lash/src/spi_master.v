    module  spi_master (
        input                 clk     ,//时钟信号
        input                 rst_n   ,//复位信号
        input                 req     ,
        input         [7:0]   din     ,
        input                 finish  ,
        output   reg          done    ,
        output   reg  [7:0]   dout    ,
         
        output   reg          spi_sclk,
        input                 spi_miso,
        output   reg          spi_mosi,
        output   reg          spi_cs   
        // output                spi_cs 
                                      
    );
    //参数定义
        localparam  SCLK_PERIOD = 16    ,
                    SCLK_RISE   = 8     ;
                    // SCLK_FALL   = 6     ;
        localparam  CNT_BIT     = 8     ;
        localparam  IDLE        = 3'b001,
                    READY       = 3'b010,
                    TRANS       = 3'b100;
    
    //信号定义
        reg   [7:0]  din_latch;
        reg   [3:0]  sclk_cnt ;
        reg          sclk_done;
        reg   [3:0]  bit_cnt  ;
        reg          csen     ;
        reg   [2:0]  state_c  ;
        reg   [2:0]  state_n  ;

    //din_latch
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                din_latch<= 0;
            else if(req)
                din_latch<= din;
            else if(sclk_cnt== SCLK_PERIOD - 2)
                din_latch<= din_latch << 1;
        end
    //状态机
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                state_c<= 0;
            else
                state_c<= state_n  ;
        end
        always@(*)begin
            case(state_c)
                IDLE :begin
                        if(req)
                            state_n = READY ; 
                        else
                            state_n = state_c;
                      end                
                READY:state_n = TRANS ; 
                TRANS:begin
                        if(done)
                            state_n = IDLE; 
                        else
                            state_n = state_c;
                      end
                default:state_n = IDLE;
            endcase
        end
    //csen
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                csen<= 0;
            else if(finish)
                csen<= 1'b0;
            else if(req)
                csen<= 1'b1;
        end
    //spi_cs
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                spi_cs<= 1'b1;
            else if(csen)
                spi_cs<= 1'b0;
            else
                spi_cs<= 1'b1;
        end
        // assign spi_cs = req;
    //sclk_cnt
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                sclk_cnt <= 0;
            else if((sclk_cnt== SCLK_PERIOD - 1)|~csen ) 
                sclk_cnt <= 0;
            else if(csen)
                sclk_cnt <=  sclk_cnt + 1'b1;
        end 
    //sclk_done
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                sclk_done<= 0;
            else if(sclk_cnt== SCLK_PERIOD - 1)
                sclk_done<= 1'b1;
            else
                sclk_done<= 1'b0;
        end  
    //spi_sclk
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                spi_sclk<= 0;
            else if((sclk_cnt== SCLK_RISE)&csen)
                spi_sclk<= 1'b1;
            else if(sclk_done)
                spi_sclk<= 1'b0;
        end   
    //bit_cnt
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                bit_cnt <= 0;
            else if((bit_cnt == CNT_BIT - 1)&sclk_done)
                bit_cnt <= 0;
            else if(sclk_done)
                bit_cnt <= bit_cnt + 1'b1;
        end   
    //done
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                done<= 0;
            else if((bit_cnt == CNT_BIT - 1)&sclk_done)
                done<= 1'b1;
            else
                done<= 1'b0;
        end
    //spi_mosi
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                spi_mosi<= 0;
            else if(sclk_done||(state_c==READY))
                spi_mosi<= din_latch[7] ;
        end
    //dout
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                dout <= 0;
            else if(sclk_cnt== SCLK_RISE - 1)
                dout <= {dout[6:0],spi_miso};
        end

           
    endmodule