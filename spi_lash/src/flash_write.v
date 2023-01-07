   `include "param.v"
    module flash_write(
       input                  clk     ,//时钟信号
       input                  rst_n   ,//复位信号
       input                  wren    ,
       input          [23:0]  wradress,
       input          [7:0]   data    ,
       input                  data_vld,
       output   reg   [1:0]   fail    ,//PP读写失败标志
       output   reg           wrready ,
       output   reg           wrdone  ,

       
       input                  done    ,
       input          [7:0]   dout    ,
       output   reg           req     ,
       output   reg   [7:0]   din     ,
       output   reg           finish  
       
    );
    //参数定义
        localparam M_IDLE  = 5'b00001,//1
                   M_WREN  = 5'b00010,//2
                   M_SE    = 5'b00100,//4
                   M_RDSR  = 5'b01000,//8
                   M_PP    = 5'b10000;//16 
        localparam S_IDLE  = 5'b00001,//1
                   S_CMD   = 5'b00010,//2
                   S_ADDR  = 5'b00100,//4
                   S_DATA  = 5'b01000,//8
                   S_DELAY = 5'b10000;//16 

    //信号定义
        reg  [23:0]  wradress_latch;
        reg  [4:0]   m_state_c     ;
        reg  [4:0]   m_state_n     ;
        reg          wel           ;
        reg          busy          ;
        reg  [2:0]   flag          ;
        reg          sidle_en      ;
        reg  [4:0]   s_state_c     ;
        reg  [4:0]   s_state_n     ;
       
        reg  [10:0]  byte_cnt      ;
        reg  [10:0]  BYTE_CNT      ;
        reg          byte_done     ;
        reg  [16:0]  delay_5ms     ;
        reg          done_5ms      ;
        reg  [9:0]   delay_3s      ;
        reg          done_3s       ;
        reg          req_en        ;
       
    
    //wradress_latch
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                wradress_latch<= 0;
            else if(wren)
                wradress_latch<=  wradress;
        end
    //主状态机
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                m_state_c<= M_IDLE;
            else
                m_state_c<= m_state_n;
        end 

        always@(*)begin
            case(m_state_c)
                M_IDLE :begin
                        if(wren)
                            m_state_n = M_WREN;
                        else
                            m_state_n = m_state_c;
                      end               
                M_WREN :begin
                        if(done_5ms&flag[0])
                            m_state_n = M_SE  ;
                        else if(done_5ms&flag[1])
                            m_state_n = M_PP  ;
                        else
                            m_state_n = m_state_c;
                      end       
                M_SE   :begin
                        if(done_3s)
                            m_state_n = M_RDSR;
                        else
                            m_state_n = m_state_c;
                      end       
                M_RDSR :begin
                        if(done_5ms&flag[1]&wel&~busy)
                            m_state_n = M_PP  ;
                        else if(done_5ms&flag[1]&(~wel&~busy ))
                            m_state_n = M_WREN ;
                        else if(done_5ms&(busy | (flag[2]&~busy)))
                            m_state_n = M_IDLE ;
                        else
                            m_state_n = m_state_c;
                      end
                M_PP   :begin
                        if(done_5ms)
                            m_state_n = M_RDSR;
                        else
                            m_state_n = m_state_c;
                      end
            endcase
        end
    //sidle_en
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                sidle_en<= 0;
            else if(wren|((m_state_c == M_WREN)|(m_state_c == M_PP))&done_5ms|((m_state_c==M_SE)&done_3s))
                sidle_en<= 1'b1;
            else if( (m_state_c== M_RDSR)&(flag[1]&~busy)&done_5ms)
                sidle_en<= 1'b1;
            else
                sidle_en<= 1'b0;
        end
    //BYTE_CNT
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                BYTE_CNT<= 0;
            else if(sidle_en)
                BYTE_CNT<= `CMD_BYTE;
            else if(((m_state_c==M_SE)|(m_state_c==M_PP))&(s_state_c==S_CMD)&byte_done)
                BYTE_CNT<= `ADDR_BYTE;
            else if((m_state_c==M_RDSR)&(s_state_c==S_CMD)&byte_done)
                BYTE_CNT<= `RDSR_BYTE;
            else if((m_state_c==M_PP)&(s_state_c==S_ADDR)&byte_done)
                BYTE_CNT<= `DATA_BYTE;
        end
    //byte_cnt
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                byte_cnt <= 0;
            else if((byte_cnt== BYTE_CNT -1)&done ) 
                byte_cnt <= 0;
            else if(done&(m_state_c != M_IDLE))
                byte_cnt <=  byte_cnt + 1'b1;
        end
    //byte_done
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                byte_done<= 0;
            else if((byte_cnt== BYTE_CNT -1)&done)
                byte_done<= 1'b1;
            else
                byte_done<= 1'b0;
        end
    //delay_5ms
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                delay_5ms <= 0;
            else if(delay_5ms== `DELAY_5MS-1) 
                delay_5ms <= 0;
            else if(s_state_n == S_DELAY)
                delay_5ms <=  delay_5ms + 1'b1;
        end
    //done_5ms
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                done_5ms<= 0;
            else if(delay_5ms== `DELAY_5MS-1)
                done_5ms<= 1'b1;
            else  
                done_5ms<= 1'b0;
        end
    //delay_3s
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                delay_3s <= 0;
            else if((delay_3s== `DELAY_3S -1 )&done_5ms) 
                delay_3s <= 0;
            else if((done_5ms)&m_state_c == M_SE)
                delay_3s <=  delay_3s + 1'b1;
        end
    //done_3s
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                done_3s<= 0;
            else if((delay_3s== `DELAY_3S -1 )&done_5ms)
                done_3s<= 1'b1;
            else
                done_3s<= 1'b0;
        end
    //wel/busy
        always@(posedge clk or negedge rst_n)begin
           if(!rst_n)begin
              wel<= 0;
              busy<= 1;
           end
           else if((m_state_c==M_RDSR)&(s_state_c == S_DATA)&done )begin
              wel<= dout[1];
              busy<= dout[0];
           end
        end
    //flag
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                flag <= 0;
            else if(wren)
                flag <= 3'b001;
            else if( m_state_c== M_SE &done_3s)
                flag <= 3'b010;
            else if(m_state_c== M_PP &done_5ms)
                flag <= 3'b100;
        end
    //从状态机
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                s_state_c<= S_IDLE;
            else
                s_state_c<=  s_state_n;
        end
        always@(*)begin
            case(s_state_c)
                S_IDLE: begin
                            if(sidle_en) 
                                s_state_n = S_CMD ;
                            else 
                                s_state_n = s_state_c;
                        end
                S_CMD : begin
                            if(m_state_c==M_WREN&byte_done) 
                                s_state_n = S_DELAY;
                            else if(((m_state_c==M_SE)|(m_state_c==M_PP))&byte_done) 
                                s_state_n = S_ADDR;
                            else if((m_state_c==M_RDSR)&byte_done)
                                s_state_n = S_DATA;
                            else 
                                s_state_n = s_state_c;
                        end            
                S_ADDR: begin
                            if((m_state_c==M_SE)&byte_done) 
                                s_state_n = S_DELAY;
                            else if((m_state_c==M_PP)&byte_done) 
                                s_state_n = S_DATA;
                            else 
                                s_state_n = s_state_c;
                        end
                S_DATA: begin
                            if(((m_state_c==M_PP)|(m_state_c==M_RDSR))&byte_done) 
                                s_state_n = S_DELAY;
                            else 
                                s_state_n = s_state_c;
                        end 
                S_DELAY: begin
                            if(( m_state_c!=M_SE)&done_5ms|( m_state_c==M_SE &done_3s)) 
                                s_state_n = S_IDLE;
                            else 
                                s_state_n = s_state_c;
                        end            
                default: s_state_n = S_IDLE;
            endcase
        end
    //finish
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                finish<= 0;
            else if((m_state_c==M_WREN)&byte_done)
                finish<= 1'b1;
            else if((m_state_c==M_SE)&(s_state_c==S_ADDR)&byte_done)
                finish<= 1'b1;
            else if(((m_state_c==M_RDSR)|(m_state_c==M_PP))&(s_state_c==S_DATA)& byte_done)
                finish<= 1'b1;
            else
                finish<= 1'b0;
        end
    //din
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                din<= 0;
            else if(wren|((m_state_c==M_RDSR)&(finish&flag[1]&~wel&~busy)))
                din <= `CMD_WREN;
            else if(m_state_c==M_WREN&byte_done&flag[0])
                din <= `CMD_SE ;
            else if(( ((m_state_c==M_SE)&(s_state_c==S_ADDR))|((m_state_c==M_PP)&(s_state_c==S_DATA)))&byte_done)
                din <= `CMD_RDSR1;            
            else if( (m_state_c == M_PP)&sidle_en)
                din <= `CMD_PP;
            // else if( ((m_state_c==M_SE)|(m_state_c== M_PP))&(s_state_c==S_CMD)&byte_done)
            //     din <= `ADDRESS1;
            // else if(((m_state_c==M_SE)|(m_state_c==M_PP))&(s_state_c== S_ADDR)&(byte_cnt ==0 )&done)
            //     din <= `ADDRESS2;
            // else if(((m_state_c==M_SE)|(m_state_c==M_PP))&(s_state_c== S_ADDR)&(byte_cnt ==1 )&done)
            //     din <= `ADDRESS3;
            else if( ((m_state_c==M_SE)|(m_state_c== M_PP))&(s_state_c==S_CMD)&byte_done)
                din <= wradress_latch[23:16];
            else if(((m_state_c==M_SE)|(m_state_c==M_PP))&(s_state_c== S_ADDR)&(byte_cnt ==0 )&done)
                din <= wradress_latch[15:8];
            else if(((m_state_c==M_SE)|(m_state_c==M_PP))&(s_state_c== S_ADDR)&(byte_cnt ==1 )&done)
                din <= wradress_latch[7:0];
            else if((m_state_c==M_PP)&(s_state_c==S_DATA)&data_vld)
                din <= data ;
            else if((m_state_c==M_RDSR)&(s_state_c==S_CMD)&byte_done)
                din <= 8'h00 ;
        end
    //req_en
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                req_en <= 0;
            else if(m_state_c==M_WREN&done_5ms)
                req_en <= 1'b1;
            else if( ((m_state_c==M_SE)|(m_state_c== M_PP))&(s_state_c==S_CMD)&byte_done)
                req_en <= 1'b1;
            else if(((m_state_c==M_SE)|(m_state_c==M_PP))&(s_state_c== S_ADDR)&(byte_cnt < BYTE_CNT -1)&done)
                req_en <= 1'b1;
            else if((m_state_c==M_RDSR)&(s_state_c==S_CMD)&byte_done)
                req_en <= 1'b1; 
            else if((m_state_c==M_RDSR)&(s_state_c==S_DATA)&(byte_cnt< BYTE_CNT -1)&done)
                req_en <= 1'b1; 
            else if((m_state_c==M_RDSR)&done_5ms&flag[1]&~busy)
                req_en <= 1'b1; 
            else if((m_state_c == M_PP)&sidle_en)
                req_en <= 1'b1;
            else if((m_state_c==M_PP)&(s_state_c==S_DATA)&data_vld)
                req_en <= 1'b1;  
            else
                req_en <= 1'b0;
        end

    //req
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                req<= 0;
            else if(sidle_en|req_en)
                req<= 1'b1;
            else
                req<= 1'b0;
        end
    //fail
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                fail<= 0;
            else if((m_state_c ==M_RDSR)&done_5ms&busy)
                fail<= 2'b01;
            else if((m_state_c ==M_RDSR)&done_5ms&flag[2]&~busy)
                fail<= 2'b10;
            else
                fail<= 2'b00;
        end
    //wrready
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                wrready<= 0;
            else if((m_state_c==M_PP)&(s_state_c== S_ADDR)&byte_done)
                wrready<= 1'b1;
            else if((m_state_c==M_PP)&(s_state_c== S_DATA)&(byte_cnt < BYTE_CNT -1 )&done)
                wrready<= 1'b1;
            else
                wrready<= 1'b0;
        end
    //wrdone
        always@(posedge clk or negedge rst_n)begin
            if(!rst_n)
                wrdone<= 0;
            else if(flag[2]&~busy&done_5ms)
                wrdone<= 1'b1;
            else
                wrdone<= 1'b0;
        end

    endmodule 