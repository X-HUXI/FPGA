    `timescale 1ns/1ps

    module tb ();
        reg             clk     ;//时钟信号
        reg             rst_n   ;//复位信号
        reg             wren    ;
        reg     [7:0]   data    ;
        reg             data_vld;
        wire    [1:0]   fail    ;
        wire            wrready ;
        wire            wrdone  ;
        
        wire            req     ;
        wire    [7:0]   din     ;
        wire            finish  ;
        wire            done    ;
        wire    [7:0]   dout    ;
        
         
        wire            spi_sclk;
        reg             spi_miso;
        wire            spi_mosi;
        wire            spi_cs  ;
        always #20 clk=~clk;
        initial begin
            clk       = 1'b1;
            #100.1;
            #2000000;
            $stop;
        end
        initial begin
            rst_n = 1'b1;
            #40;
            rst_n = 1'b0;
            #20;
            rst_n = 1'b1;
        end
        integer  i=0,j = 0,m = 0,n = 0,k=0;//用于产生地址，写入数据
        /* initial begin
            wren = 1'b0;
            #100;
            @(posedge clk );
            wren = 1'b1;
            @(posedge clk );
            wren = 1'b0;
        end */
        initial begin
            wren = 1'b0;
            data     = 1'b0;
            data_vld = 16'h0;
            #200;
            for ( j=0 ;j<12 ;j=j+1 ) begin
                if(j==0)begin
                     @(posedge clk );
                    wren = 1'b1;
                    @(posedge clk );
                    wren = 1'b0;
                end
                else 
                    @(posedge fail[0] or posedge wrdone)begin
                        @(posedge clk );
                        wren = 1'b1;
                        @(posedge clk );
                        wren = 1'b0;    
                    end
            end
        end

        initial begin
            data     = 1'b0;
            data_vld = 16'h0;
            for ( j=0 ;j<12 ;j=j+1 ) 
                for ( i=0 ;i<12 ;i=i+1 ) begin
                    @(posedge u_write.wrready)begin
                        data ={$random};
                        @(posedge clk );
                           data_vld = 1'b1;
                        @(posedge clk ); 
                            data_vld = 1'b0;
                    end
            end
        end
        initial begin
            spi_miso = 1'b0;
            #200;
            for (k = 0; k<80000 ; k = k+1 ) begin  
                @(posedge u_spi.sclk_done );
                spi_miso={$random};
            end
                
        end
        
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

            /* input                  */.done    (done    ),
            /* input          [7:0]   */.dout    (dout    ),
            /* output   reg           */.req     (req     ),
            /* output   reg   [7:0]   */.din     (din     ),
            /* output   reg           */.finish  (finish  )
            
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
    endmodule