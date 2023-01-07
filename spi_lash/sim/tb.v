    `timescale 1ns/1ps

    module tb ();
        reg             clk       ;//时钟信号
        reg             rst_n     ;//复位信号
        wire    [7:0]   rddata    ;
        wire            rddata_vld;
        wire            rddone    ;


        wire            spi_sclk  ;
        reg             spi_miso  ;
        wire            spi_mosi  ;
        wire            spi_cs    ;
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
        integer  k=0;//用于产生地址，写入数据
        initial begin
            spi_miso = 1'b0;
            #200;
            for (k = 0; k<80000 ; k = k+1 ) begin  
                @(posedge u_ctrl.u_spi.sclk_done );
                spi_miso={$random};
            end
                
        end
        
    //模块例化
        control u_ctrl(
            /* input                  */.clk        (clk       ),//时钟信号
            /* input                  */.rst_n      (rst_n     ),//复位信号
            /* output       [7:0]     */.rddata     (rddata    ),
            /* output                 */.rddata_vld (rddata_vld),
            /* output                 */.rddone     (rddone    ),

            /* output                 */.spi_sclk   (spi_sclk  ),
            /* input                  */.spi_miso   (spi_miso  ),
            /* output                 */.spi_mosi   (spi_mosi  ),
            /* output                 */.spi_cs     (spi_cs    )                          
        );  
    endmodule