module processor(
    input  rst , clk,
    input  [15:0] in,
    output [15:0] out
);

wire fetchEnableBuf,  Rdst;
wire [1:0] pc_select;
wire [15:0] readData1,readData2;
wire [31:0] pc , instruction;

wire [1:0]  o_MemBuf_Wb;
wire [15:0] o_MemBuf_alu;
wire [31:0] o_MemBuf_MemData;
wire [2:0]  o_MemBuf_Rdst;
wire [15:0] writeBackData;
// -------------------------------------------------------- Fetch Stage --------------------------------------
    wire [31:0] tmpPc, tmpInstruction;
    reg [3:0] pcPlace;
    wire [22:0] signals;

    fetch fetchObj(
        .clk(clk),                                                              //1  bits
        .pc_select(signals[22:21]),                                             //2  bits
        .pc_place(4'd0),                                                        //4  bits
        .index(3'd3),                                                           //3  bits
        .IVT(32'd12),                                                           //32  bits
        .ret(32'd27),                                                           //32  bits
        .reset(32'd57),                                                         //32  bits
        .call(16'd33),                                                          //16  bits
        .new_pc(tmpPc) ,                                                        //32  bits
        .instruction(tmpInstruction)                                            //32  bits
        // ,.intFlag(intFlag)
    );

    fetch_dec_buf fetchBuf (
        // .rst(rst),
        .clk(clk),  
        .enable(1'b1),
        .i_pc(tmpPc), 
        .i_instruction(tmpInstruction),               
        .o_pc(pc),          
        .o_instruction(instruction)
    );
// -------------------------------------------------------- Deocde Stage --------------------------------------
    reg [15:0] writeData;

    wire [1:0] o_decBuf_Wb;
    wire [5:0] o_decBuf_Mem;
    wire [10:0] o_decBuf_Ex;
    wire  o_decBuf_chgFlag ;
    wire [31:0] o_decBuf_pc;
    wire [2:0] o_decBuf_Rsrc1, o_decBuf_Rsrc2, o_decBuf_Rdst;
    wire [15:0] o_decBuf_immd, o_decBuf_ReadData1, o_decBuf_ReadData2;


    decode decodeObj(
        .clk(clk),                                                               // 1  bits
        .rst(rst),                                                               // 1  bits
        .regWrite(o_MemBuf_Wb[1]),                                               // 1  bits 
        .Rsrc1(instruction[18:16]),                                              // 3  bits
        .Rsrc2(instruction[21:19]),                                              // 3  bits
        .Rdst(o_MemBuf_Rdst),                                                    // 3  bits
        .opcode(instruction[31:25]),                                             // 7  bits 
        .writeData(writeBackData),                                               // 16 bits
        .inPort(16'b0),                                                          // 16 bits      
        .signals(signals),                                                       // 23 bits
        .readData1(readData1),                                                   // 16 bits
        .readData2(readData2)                                                    // 16 bits
    );

    dec_alu_buf dec_alu_bufObj 
    (
    // input rst,
        .clk(clk),
        .enable(1'b1),
        .i_WB( {signals[19], signals[0]}),  // 2 bits
        .i_Mem(signals[4:2]),               // 3 bits
        .i_Ex (signals[16:6]) ,             // 10 bits
        .i_chg_flag(1'b0),                  // 1 bit
        .i_pc(pc),                          // 32 bits
        .i_Rdst(instruction[24:22]),        // 3 bits
        .i_Rsrc2(instruction[21:19]),       // 3 bits 
        .i_Rsrc1(instruction[18:16]),       // 3 bits 
        .i_immd(instruction[15:0]),         // 16 bits
        .i_read_data1(readData1),           // 16 bits 
        .i_read_data2(readData2),           // 16 bits
    // ---------------------   output ---------------//
        .o_WB(o_decBuf_Wb),                     // 2 bits
        .o_Mem(o_decBuf_Mem),                   // 6 bits
        .o_Ex(o_decBuf_Ex) ,                    // 3 bits
        .o_chg_flag(o_decBuf_chgFlag),          // 1 bit
        .o_pc(o_decBuf_pc)   ,                  // 1 bit
        .o_Rsrc1(o_decBuf_Rsrc1) ,              // 3 bits 
        .o_Rsrc2(o_decBuf_Rsrc2) ,              // 3 bits
        .o_Rdst(o_decBuf_Rdst),                 // 3 bits
        .o_immd(o_decBuf_immd) ,                // 16 bits
        .o_read_data1(o_decBuf_ReadData1),      // 16 bits
        .o_read_data2(o_decBuf_ReadData2)       // 16 bits
    );

// -------------------------------------------------------- Execute Stage --------------------------------------
    wire [1:0]  o_aluBuffer_Wb;
    wire [3:0]  o_aluBuffer_flags;
    wire [5:0]  o_aluBuffer_Mem;
    wire [31:0] o_aluBuffer_pc;
    wire [2:0]  o_aluBuffer_Rdst;
    wire [15:0] o_aluBuffer_ReadData1;
    wire [15:0] o_aluBuffer_alu;
    wire [15:0] tmpAlu_Out;
    wire [3:0]  tmpFlags;

    execute ExcecuteObj(
        .clk(clk),             // 1  bit
        .data1(o_decBuf_Ex[10]),           // 1  bit
        .data2(o_decBuf_Ex[9]),           // 1  bit
        .imm(o_decBuf_Ex[8]),             // 1  bit
        .ALUsrc1(o_decBuf_Ex[7:6]),         // 2  bit
        .ALUsrc2(o_decBuf_Ex[5:4]),         // 2  bit
        .ALUoperation(o_decBuf_Ex[3:1]),    // 3  bit
        .flag_src(o_decBuf_Ex[0]),        // 1  bit
        .data1_val(o_decBuf_ReadData1),       // 16 bit
        .data2_val(o_decBuf_ReadData2),       // 16 bit
        .imm_val(o_decBuf_immd),         // 16 bit
        .ALU_out(tmpAlu_Out),          // 16 bit
        /////////////////////////////////////////////////////
        .mem_flags(o_MemBuf_MemData[31:28]),
        .input_flags(o_aluBuffer_flags), 
        .prev_ALU(o_aluBuffer_alu),
        .prev_mem(o_MemBuf_MemData[15:0]),
        .output_flags(tmpFlags)  
    );
    alu_mem_buff alu_mem_buffObj(
        // input rst,
        .clk(clk),
        .enable(1'b1),
        .i_Mem(o_decBuf_Mem),                   //6   bits
        .i_WB(o_decBuf_Wb),                     //4   bits
        .i_pc(o_decBuf_pc)  ,                   //32  bits
        .i_Rdst(o_decBuf_Rdst),                 //3   bits
        .i_alu(tmpAlu_Out) ,                              //16  bits
        .i_read_data1(o_decBuf_ReadData1) ,     //16  bits
        .i_flag(tmpFlags) ,                             //4   bits

        .o_Mem(o_aluBuffer_Mem),                   //6  bits
        .o_WB(o_aluBuffer_Wb),                     //4  bits
        .o_pc(o_aluBuffer_pc),                     //32 bits
        .o_Rdst(o_aluBuffer_Rdst),                 //3  bits
        .o_alu(o_aluBuffer_alu) ,                              //16 bits
        .o_read_data1(o_aluBuffer_ReadData1),      //16 bits
        .o_flag(o_aluBuffer_flags)                               //4  bits
    );
// -------------------------------------------------------- Memory Stage --------------------------------------

    wire [3:0]  o_MemoryStage_Wb;
    wire [15:0] o_MemoryStage_alu;
    wire [31:0] o_MemoryStage_MemData; 


    memStage MemStageObj(
        .clk(clk) ,                // 1 bit
        .i_reset(1'b0),            // 1 bit
        .i_isStack(1'b0),          // 1 bit
        .i_isPushPc(1'b0),         // 1 bit
        .i_memRead(o_aluBuffer_Mem[2]),          // 1 bit
        .i_memWrite(o_aluBuffer_Mem[1]),         // 1 bit
        .i_en32(o_aluBuffer_Mem[0]),             // 1 bit
        .i_wb(o_aluBuffer_Wb),               // 4 bit
        .i_aluData(o_aluBuffer_alu),        // 16 bit
        .i_stackData(32'd120),     // 32 bit
        .i_pc(o_aluBuffer_pc),             // 32 bit
        .i_instruction(o_aluBuffer_ReadData1),    // 32 bit


        .o_wb(o_MemoryStage_Wb) ,              // 4 bit
        .o_aluData(o_MemoryStage_alu) ,         // 16 bit
        .o_memData(o_MemoryStage_MemData)           // 32 bit
        // .o_hazardUnit()  // 20 bit
    );

    Mem_WB_buff Mem_WB_buffObj(
    .clk(clk),                 // 1 bit
    .enable(1'b1),              // 1 bit
    .i_WB(o_MemoryStage_Wb),                // 4 bit
    .i_MemData(o_MemoryStage_MemData) ,          // 32 bit
    .i_alu(o_MemoryStage_alu),               // 16 bit
    .i_Rdst(o_aluBuffer_Rdst),              // 3 bit

    .o_WB(o_MemBuf_Wb),                // 2 bit
    .o_MemData(o_MemBuf_MemData) ,          // 32 bit
    .o_alu(o_MemBuf_alu),               // 16 bit
    .o_Rdst(o_MemBuf_Rdst)               // 3 bit
);


// ----------------------- WriteBack Stage --------------------------------------

writeBack writeBackObj(
    .sel(o_MemBuf_Wb[0]),
    .memData(o_MemBuf_MemData),       // 32bit
    .aluData(o_MemBuf_alu),       // 16bit

    .writeBackData(writeBackData)    // 16 bit
);

endmodule