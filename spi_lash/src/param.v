//AT26DF3321命令参数定义    
    `define CMD_RDID    8'h4B      //读取ID
    `define CMD_READ    8'h03      //读数据
    `define CMD_WREN    8'h06      //写使能
    `define CMD_RDSR1   8'h05      //读状态寄存器1
    `define CMD_RDSR2   8'h35      //读状态寄存器2
    `define CMD_SE      8'h20      //扇区擦除
    `define CMD_PP      8'h02      //页编程
//字节参数
    `define CMD_BYTE    1          //命令1字节
    `define ADDR_BYTE   3          //地址3字节
    `define DATA_BYTE   12         //数据12字节
    `define ID_BYTE     3          //ID 3字节
    `define RDSR_BYTE   10         //读状态寄存器最大读1000次
    `define RDID_BYTE   10         //读状态寄存器最大读1000次
    // `define DELAY_5MS   125        //5ms _000  
    // `define DELAY_3S    6          //0.3s 0 
    `define DELAY_5MS   125_000    //5ms   
    `define DELAY_3S    600        //0.3s  

//flash存储地址
    `define ADDRESS     24'h3FFF00
    `define ADDRESS1    8'h3F
    `define ADDRESS2    8'hFF
    `define ADDRESS3    8'h00

    `define SECTOR1     24'h3FFF00
    `define SECTOR2     24'h3FEF00