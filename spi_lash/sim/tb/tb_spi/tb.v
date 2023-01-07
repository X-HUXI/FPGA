    `timescale 1ns/1ps

    module tb ();
        reg             clk     ;//时钟信号
        reg             rst_n   ;//复位信号
        reg             req     ;
        reg     [7:0]   din     ;
        reg             finish  ;
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
        initial begin
            req = 1'b0;
            din = 16'h0;
            #200;
            for (m = 0; m<522 ; m = m+1 ) begin
                  din ={$random};
                for (n = 0; n< 65   ; n = n+1 ) begin
                    if(n==1)   req = 1'b1;
                    else if(n==2 )  req = 1'b0;
                    @(posedge clk );
                end
            end
        end
        initial begin
            finish = 1'b0;
            #200; 
            for(i=0;i<60;i=i+1)begin
                for (j = 0; j<8 ; j = j+1 )  
                    @(posedge u_spi.done );
                finish = 1'b1;
                @(posedge clk);
                finish = 1'b0;
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