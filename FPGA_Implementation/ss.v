
// In powers of 2 above 1
`define IADDR_bits 21
`define DADDR_bits 30 // >= IADDR_bits

`define DEB 0

`define VLEN 256 
`define VLEN_Log2 $clog2(`VLEN)
// In powers of 2 above 1
`define IL1sets 64

`define DL1sets 32
`define DL1ways 4

`define DL2sets 32
`define DL2ways 4
`define DL2block 16384 // 512-byte
`define DL2subblocks 32

`define IL1setsLog2 $clog2(`IL1sets)
`define DL1setsLog2 $clog2(`DL1sets)
`define DL1waysLog2 $clog2(`DL1ways)

`define DL2setsLog2 $clog2(`DL2sets)
`define DL2waysLog2 $clog2(`DL2ways)
`define DL2block_Log2 $clog2(`DL2block)
`define DL2subblocks_Log2 $clog2(`DL2subblocks)

`define VECTOR_SIZE 32
`define OCC_WIDTH 4

`define SHCT_SIZE 256


module IL1Cache (clk, reset, PC, instr, ready,
	en, PCB, instrB, readyB);
	input clk, reset;
	input [`IADDR_bits-1:0] PC;  
    output reg [31:0] instr;
    output reg ready;
    
    output reg en;
    output reg [`IADDR_bits-1:0] PCB;
    input [`VLEN-1:0] instrB;
    input readyB;

    /*(* ram_style = "distributed" *)*/ reg [`VLEN-1:0] mem [`IL1sets-1:0];
    reg [`IADDR_bits-`IL1setsLog2-`VLEN_Log2+3-1:0] tag_array [`IL1sets-1:0];
    reg valid [`IL1sets-1:0];
    
    wire [`IL1setsLog2-1:0] set; assign set = PC>>(`VLEN_Log2-3);
    wire [`IADDR_bits-`IL1setsLog2-`VLEN_Log2+3-1:0] tag; assign tag = PC>>(`VLEN_Log2-3+`IL1setsLog2);
    
    wire hit; assign hit = valid[set] && (tag_array[set]==tag);
    reg [`VLEN_Log2-5-1:0] roffset; //assign roffset = PC>>2;
    
	reg pending; integer i;  
	
	always @( posedge clk ) begin
		if (reset) begin
			for (i=0; i<`IL1sets; i=i+1) begin
				valid[i]<=0;	
				tag_array[i]<=0;
			end
			pending<=0;	en<=0;

		end else begin

			if (readyB) begin
				mem[set]<=instrB;
				if (`DEB)$display("filling set %d with %h ready %d",set,instrB, ready);
				instr<=instrB[(roffset+1)*32-1-:32];     
			end else begin
				instr<=mem[set][(PC[`VLEN_Log2-5-1+2:2]+1)*32-1-:32];
//$display("non filling");
			end
			
			ready<=hit||readyB;		
			if (`DEB)$display("ihit %d roffset %d %h",hit,roffset,PC);

			en<=0;
			if ((!hit) && (!pending)) begin 
				en<=1;
				pending<=1;
				roffset <= PC>>2;		
				PCB<=PC;
				if (`DEB)$display("requesting %h",PC);
			end
			
			if (readyB) begin
				pending<=0;			
				valid[set]<=1;
				tag_array[set]<=tag;
			end	

		end
	end		
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, 
		PC, instr, ready, en, PCB, instrB, readyB, hit);
	end
endmodule

module optgen_DL1 
(
    input wire clk,
    input wire reset,
    input wire [`DL1setsLog2-1:0] set,
    input wire [4:0] curr_timestep,
    input wire [4:0] last_timestep,
    input wire is_reuse, 
	input wire access,
	// input wire [`IADDR_bits-1:0] pc,      
    output reg should_cache          
);
    (* ram_style = "block" *) reg [`OCC_WIDTH-1:0] occupancy_vector [`DL1sets-1:0][`VECTOR_SIZE-1:0];
    integer s, q, q_idx;
//	reg [4:0] interval;
	// function [7:0] hash;
	// 	input [`IADDR_bits-1:0] pc;  
	// 	begin
	// 		hash = pc[6:0] ^ pc[13:7] ^ pc[20:14];
	// 	end
	// endfunction


    // wire [7:0] index;
    // assign index = hash(pc);
    always @(posedge clk) begin
        if (reset) begin
            for (s = 0; s < `DL1sets; s = s + 1)
                for (q = 0; q < `VECTOR_SIZE; q = q + 1)
                    occupancy_vector[s][q] = 0;
            should_cache = 1;
//			interval <= 0;
        end 
		if (access) begin
			// $display("last timestep ", last_timestep, " curr_timestep ", curr_timestep, " pc ", pc, " is_reuse ", is_reuse);
			if (is_reuse) begin
				should_cache = 1;
				occupancy_vector[set][curr_timestep] = 0;
				// interval <= curr_timestep - last_timestep;
				// $display("%d", interval);
				// $display("%d %d", last_timestep, curr_timestep);

				for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
					if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE]>=`DL1ways) begin
						should_cache = 0;
						// $display("ov bigger than ways");
					end
				end

				// for (q_idx = last_timestep; q_idx != curr_timestep; q_idx = (q_idx + 1) % `VECTOR_SIZE) begin
				// 	if (occupancy_vector[set][q_idx] >= `DL1ways) begin
				// 		should_cache = 0;
				// 		// $display("ov bigger than ways");
				// 	end
				// end
				if (should_cache) begin
					
					
					for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
						if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] < `DL1ways) begin
							occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] = occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] + 1;
							// $display("ov increment");
						end
					end
				end
				// $display("DL1: should_cache: ",should_cache);
			end else begin
				should_cache = 0;
				occupancy_vector[set][curr_timestep] = 0;
				// $display("ov not reused");
			end
			// $display("DL1: should_cache: ",should_cache, " ", pc);
			
		end
		
    end
endmodule

module optgen_DL2 
(
    input wire clk,
    input wire reset,
    input wire [`DL2setsLog2-1:0] set,
    input wire [4:0] curr_timestep,
    input wire [4:0] last_timestep,
    input wire is_reuse,
	input wire access,
	// input wire [`IADDR_bits-1:0] pc,      
    output reg should_cache          
);
    (* ram_style = "block" *) reg [`OCC_WIDTH-1:0] occupancy_vector [`DL2sets-1:0][`VECTOR_SIZE-1:0];
    integer s, q, q_idx;
//	reg [4:0] interval;
	// function [7:0] hash;
	// 	input [`IADDR_bits-1:0] pc;  
	// 	begin
	// 		hash = pc[6:0] ^ pc[13:7] ^ pc[20:14];
	// 	end
	// endfunction


    // wire [7:0] index;
    // assign index = hash(pc);
    always @(posedge clk) begin
        if (reset) begin
            for (s = 0; s < `DL2sets; s = s + 1)
                for (q = 0; q < `VECTOR_SIZE; q = q + 1)
                    occupancy_vector[s][q] = 0;
            should_cache = 1;
//			interval <= 0;
        end 
		if (access) begin
			// $display("last timestep ", last_timestep, " curr_timestep ", curr_timestep, " pc ", pc, " is_reuse ", is_reuse);
			if (is_reuse) begin
				should_cache = 1;
				occupancy_vector[set][curr_timestep] = 0;
				// interval <= curr_timestep - last_timestep;
				// $display("%d", interval);
				// $display("%d %d", last_timestep, curr_timestep);
				for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
					if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE]>=`DL1ways) begin
						should_cache = 0;
						// $display("ov bigger than ways");
					end
				end
				if (should_cache) begin
					
					
					for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
						if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] < `DL1ways) begin
							occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] = occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] + 1;
							// $display("ov increment");
						end
					end
				end
				// $display("DL2: should_cache: ",should_cache);
			end else begin
				should_cache = 0;
				occupancy_vector[set][curr_timestep] = 0;
				// $display("ov not reused");
			end
			// $display("DL2: should_cache: ",should_cache, " ", pc);
			
		end
		
    end
endmodule

module hawkeye_predictor_DL1 (
    input wire clk,
    input wire reset,
    input wire [`IADDR_bits-1:0] pc,
    input wire train_up,
    input wire train_down,
	input wire access,
    output reg [2:0] prediction
);

    (* ram_style = "block" *) reg [2:0] shct [0:`SHCT_SIZE-1];

    function [7:0] hash;
		input [`IADDR_bits-1:0] pc;  
		begin
			hash = pc[6:0] ^ pc[13:7] ^ pc[20:14];
		end
	endfunction

    wire [7:0] index;
    assign index = hash(pc);
    integer i;
    always @(posedge clk or posedge reset) begin
	// always @(posedge access) begin
        if (reset) begin
            for (i = 0; i < `SHCT_SIZE; i = i + 1) begin
                shct[i] = 3'b100;
				prediction = shct[i];
			end
        end else if (access) begin
            if (train_up && shct[index] > 3'b000) begin
                shct[index] = shct[index] - 1;
				prediction = shct[index];
				// $display("Train up");
            end
            else if (train_down && shct[index] < 3'b111) begin
                shct[index] = shct[index] + 1;
				prediction = shct[index];
				// $display("Train Down");
            end
			// $display("DL1: prediction: ",prediction, " ", index, " ", pc);
        end
		// $display("DL1: prediction: ",shct[index][2]);
		// 
		// if (access) begin 
		// $display("DL1: prediction: ",shct[index], " ", index, " ", pc);
		// end
    end
    // assign prediction = shct[index];
endmodule

module hawkeye_predictor_DL2 (
    input wire clk,
    input wire reset,
    input wire [`IADDR_bits-1:0] pc,
    input wire train_up,
    input wire train_down,
	input wire access,
    output reg [2:0] prediction
);

    (* ram_style = "block" *) reg [2:0] shct [0:`SHCT_SIZE-1];

    function [7:0] hash;
		input [`IADDR_bits-1:0] pc;  
		begin
			hash = pc[6:0] ^ pc[13:7] ^ pc[20:14];
		end
	endfunction

    wire [7:0] index;
    assign index = hash(pc);
    integer i;
    always @(posedge clk or posedge reset) begin
	// always @(posedge access) begin
        if (reset) begin
            for (i = 0; i < `SHCT_SIZE; i = i + 1) begin
                shct[i] = 3'b100;
				prediction = shct[i];
			end
        end else if (access) begin
            if (train_up && shct[index] > 3'b000) begin
                shct[index] = shct[index] - 1;
				prediction = shct[index];
				// $display("Train up");
            end
            else if (train_down && shct[index] < 3'b111) begin
                shct[index] = shct[index] + 1;
				prediction = shct[index];
				// $display("Train Down");
            end
			// $display("DL2: prediction: ",prediction, " ", index, " ", pc);
        end
		// $display("DL2: prediction: ",shct[index][2]);
		// 
		// if (access) begin 
		// $display("DL2: prediction: ",shct[index], " ", index, " ", pc);
		// end
    end
    // assign prediction = shct[index];
endmodule

module DL1cache (clk, reset,cycles, 
		addr, en, we, din, dout, dready, accepting, flush_in,
		addrB, enB, weB, dinB, doutB, dreadyB, acceptingB, flush_out,pc_in);
	input clk, reset; 
	input[31:0] cycles;
	input [`DADDR_bits-1:0] addr;	
    input en;
    input [`VLEN/8-1:0] we;    
    input [`VLEN-1:0] din;
    output reg [`VLEN-1:0] dout;
    output dready;
    output accepting;
    input flush_in;
    output reg [`DADDR_bits-1:0] addrB;	
    output reg enB;
    output reg weB;    
    input [`VLEN-1:0] dinB;
    output reg [`VLEN-1:0] doutB;
    input dreadyB;
    input acceptingB;
    output reg flush_out;
	input [`IADDR_bits-1:0] pc_in;
    
    (* ram_style = "block" *) reg [`VLEN-1:0] way [`DL1ways-1:0][`DL1sets-1:0] ;
    reg [`VLEN-1:0] rdata [`DL1ways-1:0];
    reg [`VLEN-1:0] wdata;

	reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_array [`DL1sets-1:0][`DL1ways-1:0];
    reg [`DL1ways-1:0] dirty [`DL1sets-1:0];
    reg [`DL1ways-1:0] valid [`DL1sets-1:0];

    reg [2:0] rrpv [`DL1sets-1:0][`DL1ways-1:0];

    wire [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag; 
    assign tag = addr>>(`DL1setsLog2+(`VLEN_Log2-3));
    
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] wtag ;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] wtag_next; reg wvalid;
        
    wire access; assign access = (en||(we!=0));    
   
    reg waiting; reg waiting_en;
    reg flushing; 
    reg [`DL1setsLog2+`DL1waysLog2+1-1:0] writethrough_block;
    
    wire [`DL1setsLog2-1:0] writethrough_set; assign writethrough_set = writethrough_block[`DL1setsLog2+`DL1waysLog2-1:`DL1waysLog2];
    wire [`DL1waysLog2-1:0] writethrough_way; assign writethrough_way = writethrough_block[`DL1waysLog2-1:0];
    
    wire [`DL1setsLog2-1:0] set; assign set = (flushing && !waiting)?writethrough_set:(addr>>(`VLEN_Log2-3)); // modulo implied
    //reg [`DL1setsLog2-1:0] from_auto_wt_set;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_real; 
    reg [`DL1setsLog2-1:0] set_real; 
    always @(*) begin 
    	if (reset) begin 
    		tag_real=0;set_real=0;
    	end else begin
    		if (access) begin     			
    			tag_real=tag; set_real=set;
    		end
    	end
    end
    
    reg [`DL1ways-1:0] we_local; reg [`DL1setsLog2-1:0] baddr;
    reg [`DL1setsLog2-1:0] bset;
    
    reg [`DADDR_bits-1:0] writeback_addr;
		
    reg hit;  
    reg miss; 
    reg [`DL1waysLog2-1:0] candidate; //reg [`DL1waysLog2-1:0] last_candidate;
            
    genvar j; integer j_;
    
//    reg zero_found;

	// reg [4:0] last_access_timestep [`DL1sets-1:0][256]; 
    reg [4:0] curr_timestep;  
    reg [`IADDR_bits-1:0] access_pc;

    wire is_sampled_set = 1'b1; 
    reg is_reuse;
    wire should_cache;
    wire [2:0] prediction;
    reg train_up, train_down;

    for (j=0;j<`DL1ways;j=j+1) begin   
   	
		always @(posedge clk) begin
		
			if (we_local[j]) begin
				way[j][baddr]<=wdata;

				if (`DEB)$display("...storing1 %h at set %d addr %h",wdata, baddr,{wtag,baddr});				
			end         
			rdata[j]<=way[j][set];
			if (`DEB)if (en&&hit) $display("...loading %h from set %d way %d addr %h", way[j][set], j, set, addr);
		
		end
	end
		
	reg we_pending; reg[`VLEN/8-1:0] we_pending_v; reg [`VLEN-1:0] we_pending_data;
	reg en_pending; reg [`VLEN/8-1:0] en_pending_write; reg [`DADDR_bits-1:0] en_pending_addr;
	reg writeback;

	integer i,k;
	
	assign accepting = !(we_pending||we||en||(waiting)||flushing);	
	
	reg [`DL1setsLog2-1:0] last_set; reg we_local_prev;	
	reg [(`VLEN_Log2-3)-2-1:0] roffset;

	reg ready;
	wire load_from_prev_lev=dreadyB && waiting_en;//(en_pending_write==0);
	assign dready=ready||load_from_prev_lev;
	
	reg read_once;
	reg [`DL1waysLog2-1:0] hit_way;
	reg [`DL1waysLog2-1:0] miss_way;
	
	wire [`VLEN-1:0] rdata_updated;
	wire hitw;  
    assign hitw = (wtag==tag_real) && (set_real==baddr) && wvalid;
	
	assign rdata_updated=(hitw)?wdata:rdata[hit_way];
	reg full_line_write_miss;
	reg [61:0] hit_count;
	reg [61:0] access_count;
//	reg found_victim;
	reg [2:0] max_rrpv;
	reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_history [`DL1sets-1:0][`VECTOR_SIZE-1:0];
	(* ram_style = "block" *) reg [4:0] timestep_history [`DL1sets-1:0][`VECTOR_SIZE-1:0];
//	integer h;
	reg found_tag_match;
	reg [4:0] last_timestep_for_tag;
	// reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] last_access_tag [`DL1sets-1:0][256];
	

	optgen_DL1 optgen_DL1_inst (
        .clk(clk), 
        .reset(reset),
        .set(set),
        .curr_timestep(curr_timestep),
        .last_timestep(last_timestep_for_tag),
        .is_reuse(is_reuse),
		.access(access),
		// .pc(access_pc),
        .should_cache(should_cache)
    );

    hawkeye_predictor_DL1 predictor_DL1_inst (
        .clk(clk), 
        .reset(reset),
        .pc(access_pc),
        .train_up(train_up),
        .train_down(train_down),
		.access(access),
        .prediction(prediction)
    );

	always @( posedge clk ) begin
		if (reset) begin

            for (i=0; i<`DL1sets; i=i+1) begin				  
                dirty[i]<=0;
                valid[i]<=0;
                for (j_ = 0; j_ < `DL1ways; j_ = j_ + 1) begin
                    rrpv[i][j_] <= 3'b111;
                end
            end

			en_pending<=0;
			roffset<=0;	
			writethrough_block<=0; wtag<=0; wvalid<=0; we_pending<=0; waiting_en<=0;
			writeback<=0;	waiting<=0; waiting_en<=0; read_once<=0; baddr<=0;
			
			flush_out<=0; flushing<=0; full_line_write_miss<=0;
			
			hit_count<=0; access_count<=0; 
			
            train_up <= 0;
            train_down <= 0;

			

            
            for (i = 0; i < `DL1sets; i = i + 1) begin
                for (k = 0; k < `VECTOR_SIZE; k = k + 1) begin
                    tag_history[i][k] = 0;
					timestep_history[i][k] = 0;
                end
            end
		end else begin
            

			we_local <=0; we_pending<=0; ready<=0;
			weB<=0; enB<=0;
			
			if (flush_in) begin flushing<=1; end
			
			last_set<=set; 
			
			if (en) roffset<=addr[(`VLEN_Log2-3)-1:2];						
			
            access_pc <= pc_in; 
			// $display("access", access);
			
			if (access) begin
				// $display("L1 train_up: %d train_down %d prediction %d train_up_count: %d train_down_count %d", train_up, train_down, prediction, train_up_count, train_down_count);
				access_count<=access_count+1;
                
				if (`DEB)$display("DL1 Access hit %d set %d", hit, set);
                hit = 0;
                miss = 1;
                candidate = 0;
                
                for (j_ = 0; j_ < `DL1ways; j_ = j_ + 1) begin
                    if ((tag_array[set][j_] == tag) && valid[set][j_]) begin
                        hit = 1;
                        miss = 0;
                        candidate = j_;
                    end
                end

                if (!hit) begin
                        max_rrpv = 0;
                        for (j_ = 0; j_ < `DL1ways; j_ = j_ + 1) begin
                            if (rrpv[set][j_] >= max_rrpv) begin
                                max_rrpv = rrpv[set][j_];
                                candidate = j_;
                            end
						end
                end

                if (should_cache) begin
					train_up <= 1;
					// $display("DL1: train_up");
				end else begin
					train_down <= 1;
					// $display("DL1: train_down");
				end

                if (is_sampled_set) begin
				
					found_tag_match = 0;
					is_reuse = 0;
					curr_timestep = curr_timestep + 1;
					last_timestep_for_tag = 0;

					for (j_ = 0; j_ < `VECTOR_SIZE; j_ = j_ + 1) begin
						if (tag_history[set][j_] == tag && !found_tag_match) begin
							found_tag_match = 1;
							is_reuse = 1;
							last_timestep_for_tag = timestep_history[set][j_];
							timestep_history[set][j_] = curr_timestep;
						end
					end

					if (!found_tag_match) begin
						for (j_ = 0; j_ < `VECTOR_SIZE-1; j_ = j_ + 1) begin
							tag_history[set][j_] = tag_history[set][j_+1];
							timestep_history[set][j_] = timestep_history[set][j_+1];
						end
						tag_history[set][`VECTOR_SIZE-1] = tag;
						timestep_history[set][`VECTOR_SIZE-1] = curr_timestep;
					end

					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " tag_history: ", tag_history[set][`VECTOR_SIZE-1]," timestep_history: ", timestep_history[set][`VECTOR_SIZE-1], " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag);
					
				end

                if (hit) begin
                    hit_count<=hit_count+1;
                    // hit_rate<=(hit_count*100)/access_count;
                    // $display("L1 hit_count %d, access_count %d",hit_count, access_count);

                    if (prediction > 4) begin
                        rrpv[set][candidate] <= 3'b111; 
                    end else begin
                        rrpv[set][candidate] <= 3'b000; 
                    end

                    // $display("hit1 set %d tag %h way %h",set, tag, candidate);
                    if (en) ready<=1;
                    
                    if (we!=0) begin 

                        we_pending<=(last_set!=set) && !hitw;
                                                        
                        we_pending_v=we<<(addr[(`VLEN_Log2-3)-1:2]*4);	
                        wtag_next=tag;bset=set;

                        we_pending_data=din<<(addr[(`VLEN_Log2-3)-1:2]*32);
                        
                        dirty[set][candidate]<=1;											
                        
                        
                        if (`DEB)$display("writeL1 %h at %h was_dirty %h we %h off %d",din,addr, dirty[set][candidate],we, addr[(`VLEN_Log2-3)-1:2]);
                    end	
                    hit_way=candidate;
			    end

                if (miss) begin
					
                    if (prediction > 4) begin
                        
                        rrpv[set][candidate] <= 3'b111;
                        
                    end else begin
                        // Cache-averse RRIP = 7
						rrpv[set][candidate] <= 3'b000;

						for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin

						if (j_ != candidate && rrpv[set][j_] < 3'b110) begin 
							rrpv[set][j_] <= rrpv[set][j_] + 1;
						end
                        
                        end
                    end

                    if (`DEB)$display("miss set %d tag %h way %d",set, tag, candidate);
                    en_pending_addr<={tag,set,{(`VLEN_Log2-3){1'b0}}};

                    en_pending_write<=we<<(addr[(`VLEN_Log2-3)-1:2]*4);	
                    if (`DEB)if (we!=0) 
                        $display("writeL1 %h at %h tag %h way %d", din, addr,tag, candidate);		
                        
                    we_pending_data=din<<(addr[(`VLEN_Log2-3)-1:2]*32);
                                    
                    if (dirty[set][candidate]&&valid[set][candidate]) begin

                        writeback<=1;
                        read_once<=1;

                        addrB<={tag_array[set][candidate],set,{(`VLEN_Log2-3){1'b0}}};		
                    end else begin 
                        enB<=acceptingB; addrB<={tag,set,{(`VLEN_Log2-3){1'b0}}};
                        en_pending<=!acceptingB;					
                    end
                    
                    valid[set][candidate]<=1;
                    dirty[set][candidate]<=we!=0;
                    tag_array[set][candidate]<=tag;
                    // last_pc[set][candidate] <= access_pc;

                    waiting<=1;
                    waiting_en<=en;
                    full_line_write_miss<=0;
                    
                    if((we=={(`VLEN/8){1'b1}})) begin
                        full_line_write_miss<=1;
                        en_pending<=0; enB<=0;
                        waiting<=dirty[set][candidate]&&valid[set][candidate];
                        wdata<= din; 

                        we_local[candidate]<=1; wvalid<=1;

                        if (`DEB)$display("we %h din %h rof %d",we,din, addr[(`VLEN_Log2-3)-1:2]);
                        if (`DEB)$display("STORE_PEND finished %d",cycles+1);

                    end
                        
                    wtag<=tag; baddr<=set;				
                    miss_way<=candidate;

			    end
			end
			
			
			if (we_pending  
				||(hit&&(we!=0)&&((last_set==set)|| hitw))
				) begin
				we_local[hit_way]<=1; wvalid<=1; wtag<=wtag_next; baddr<=bset;
				for (i=0; i<`VLEN/8; i=i+1) 
					wdata[(i+1)*8-1-:8]<= we_pending_v[i]?
						we_pending_data[(i+1)*8-1-:8]:
						 ((hitw)?wdata[(i+1)*8-1-:8]:
						 rdata[hit_way][(i+1)*8-1-:8]
						 );	
				if (`DEB)$display("STORE_PEND finished %d",cycles+1);

			end
		
					
			if (writeback) begin 	
				if (read_once) 
					doutB<=rdata[miss_way];
				read_once<=0;

				if (acceptingB)	begin			
					weB<=1;  
					
					if (`DEB)$display("WritebackL1 %h at %h",read_once?rdata[miss_way]:doutB, addrB);
														
					if (flushing && !waiting) begin
						doutB<=rdata[writethrough_way];
						dirty[set][writethrough_way]<=0;
						writethrough_block<=writethrough_block+1;
						if (`DEB)$display("DL1writethrough_block %d set %d way %d addr %h", writethrough_block, writethrough_set,writethrough_way,addrB);
									
					end	else begin
						en_pending<=!full_line_write_miss;
						if (full_line_write_miss) waiting<=0;						
					end
							
					writeback<=0;				
				end					
								
			end else if (flushing && acceptingB && !waiting) begin
			
				addrB<={tag_array[set][writethrough_way],set,{(`VLEN_Log2-3){1'b0}}};
				if (dirty[set][writethrough_way]&&valid[set][writethrough_way]) begin	
					writeback<=1;
				end else begin
					writeback<=0;
					writethrough_block<=writethrough_block+1;
					if (`DEB)$display("writethrough_block %d set %d way %d ", writethrough_block, writethrough_set,writethrough_way);	
				end
				
				
				if (writethrough_block[`DL1setsLog2+`DL1waysLog2+1-1]==1) begin
					flush_out<=1;	
					writethrough_block<=0;				
				end												
			end 
			
			if (flush_out) begin flushing<=0; flush_out<=0; end 
									
			if (en_pending && acceptingB) begin 
				enB<=1; addrB<=en_pending_addr; 
				en_pending<=0;
			end
			
			if (dreadyB) begin
				waiting<=0; waiting_en<=0;
				if (`DEB)$display("Reading %h from DL2 addr %h",dinB,addrB);
				we_local[miss_way]<=1; wvalid<=1; 
				
				for (i=0; i<`VLEN/8; i=i+1) 
					wdata[(i+1)*8-1-:8]<= en_pending_write[i]?
						we_pending_data[(i+1)*8-1-:8]: dinB[(i+1)*8-1-:8];
				if (`DEB && (en_pending_write!=0))$display("STORE_PEND finished %d",cycles+1);

			end
		end		
	end	
	
	always @(*) begin
		if (roffset==0) // also case of vectors, where we want the entire block
			dout=load_from_prev_lev? dinB: rdata_updated;
		else
			dout=load_from_prev_lev? dinB[32*(roffset+1)-1-:32]:
					rdata_updated[32*(roffset+1)-1-:32];	
	end
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, 
		addr, en, we, din, dout, dready, accepting,
		addrB, enB, weB, dinB, doutB, dreadyB, acceptingB,
		accepting,acceptingB,en_pending,writeback,we_local,we_pending,weB,enB,last_set,hitw,
		dready,miss,hit,we,en,ready,waiting,waiting_en, wdata,rdata_updated,wtag,tag,flushing
		);
	end
endmodule // DL1cache

module DL2cache (clk, reset, cycles,
		addr, en, we, din, dout, dready, accepting, flush_in,
		addrB, enB, weB, dinBstrobe, dinB, doutBstrobe, doutB, dreadyB, accR, accW, flush_out, pc_in);
	input clk, reset; 
	input [31:0] cycles;
	input [`DADDR_bits-1:0] addr;	
    input en;
    input we;    
    input [`VLEN-1:0] din;
    output reg [`VLEN-1:0] dout;
    output dready;
    output accepting;
    input flush_in;
    output reg [`DADDR_bits-1:0] addrB;	
    output reg enB;
    output reg /*[`VLEN/8-1:0]*/ weB;    
    input [`DL2subblocks_Log2-1:0] dinBstrobe;
    input [`DL2block/`DL2subblocks-1:0] dinB;
    output reg [`DL2subblocks_Log2-1:0] doutBstrobe;
    output /*reg*/ [`DL2block/`DL2subblocks-1:0] doutB;
    input dreadyB;
    input accR;
    input accW;
    output reg flush_out;
	input [`IADDR_bits-1:0] pc_in;
    
    (* ram_style = "block" *) reg [`DL2block/`DL2subblocks-1:0] way [`DL2ways-1:0][`DL2sets*`DL2subblocks-1:0] ;
    reg [`DL2block/`DL2subblocks-1:0] rdata [`DL2ways-1:0];
    reg [`DL2block/`DL2subblocks-1:0] wdata;

	reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] tag_array [`DL2sets-1:0][`DL2ways-1:0];
    reg [`DL2ways-1:0] dirty [`DL2sets-1:0];
    reg [`DL2ways-1:0] valid [`DL2sets-1:0];
	reg [2:0] rrpv [`DL2sets-1:0][`DL2ways-1:0]; 

    wire [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] tag; 
    assign tag = addr>>(`DL2setsLog2+(`DL2block_Log2-3));
    
    reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] wtag;
    reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] wtag_next; reg wvalid;
    
    wire access; assign access = (en||we);  
   
    reg flushing; reg waiting; reg waiting_en;

    reg [`DL2setsLog2+`DL2waysLog2+1-1:0] writethrough_block;
    wire [`DL2setsLog2-1:0] writethrough_set; assign writethrough_set = writethrough_block[`DL2setsLog2+`DL2waysLog2-1:`DL2waysLog2];
    wire [`DL2waysLog2-1:0] writethrough_way; assign writethrough_way = writethrough_block[`DL2waysLog2-1:0];
        
    wire [`DL2setsLog2-1:0] set; assign set = (addr>>(`DL2block_Log2-3)); // modulo implied
    
    wire [`DL2subblocks_Log2-1:0] access_strobe; 
    reg  [`DL2subblocks_Log2-1:0] read_strobe;
    reg  [`DL2subblocks_Log2-1:0] write_strobe;
    assign access_strobe=addr>>(`DL2block_Log2-`DL2subblocks_Log2-3);
    	
	reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] tag_real; 
    reg [`DL2setsLog2-1:0] set_real; 
    always @(*) begin 
    	if (reset) begin 
    		tag_real=0;set_real=0;
    	end else begin
    		if (access) begin
    			tag_real=tag; set_real=set;
    		end
    	end
    end
    
    wire [`DL2setsLog2+`DL2subblocks_Log2-1:0] subset; 
	assign subset={	(flushing && !waiting)?writethrough_set:set_real,
				access?access_strobe:read_strobe};
		
    reg [`DL2ways-1:0] we_local; reg [`DL2setsLog2-1:0] baddr;
    reg [`DL2setsLog2-1:0] bset;
    reg [`DADDR_bits-1:0] writeback_addr;
    	
    reg hit;  
    reg miss; 
    reg [`DL2waysLog2-1:0] candidate;
            
    genvar j; integer j_;
    
//    reg zero_found;        


    // reg [4:0] last_access_timestep [`DL2sets-1:0][256]; 
    reg [4:0] curr_timestep; 
    

    // reg [63:0] last_pc [`DL2sets-1:0][`DL2ways-1:0]; 
    reg [`IADDR_bits-1:0] access_pc; 
    

    wire is_sampled_set = 1; 
    reg is_reuse;
    wire should_cache;
    wire prediction;
    reg train_up, train_down;

    for (j=0;j<`DL2ways;j=j+1) begin   
   	
		always @(posedge clk) begin
		
			if (we_local[j]) begin
				way[j][{baddr,write_strobe}]<=wdata;

				if (`DEB)$display("...storing2 %h at set %d addr%h way %d",wdata, baddr,{wtag,baddr,write_strobe,{(`DL2block_Log2-`DL2subblocks_Log2-3){1'b0}}},j);
			end         
			rdata[j]<=way[j][subset];
			if (`DEB)if (en&&hit &&j==candidate) $display("...loading %h from set %d (%d) way %d addr %h tag %h ", way[j][subset], set, subset, j, addr, tag);
 			
		end
	end
	
	reg we_pending; reg[`DL2block/`DL2subblocks/`VLEN-1:0] we_pending_v; 
	reg [`VLEN-1:0] we_pending_data;
	
	reg en_pending; reg [`DL2block/`DL2subblocks/`VLEN-1:0] en_pending_write; reg [`DADDR_bits-1:0] en_pending_addr;
	reg writeback; 

	integer i,k;
	
	assign accepting = !(we_pending||we||en||(waiting)||flushing); 
	
	reg [`DL2setsLog2-1:0] last_set; reg we_local_prev;	
	reg [(`DL2block_Log2-3)-(`DL2subblocks_Log2)-(`VLEN_Log2-3)-1:0] roffset;
	
	reg [`DL2subblocks_Log2-1:0] waiting_en_strobe;
	reg ready;
	wire load_from_prev_lev=dreadyB && waiting_en && (waiting_en_strobe==dinBstrobe);	
	
	assign dready=ready||load_from_prev_lev;
	
	reg read_once;
	reg [`DL2waysLog2-1:0] hit_way;
	reg [`DL2waysLog2-1:0] miss_way;
	
	wire [`DL2block-1:0] rdata_updated;
	wire hitw;  assign hitw = (wtag==tag_real) && (subset=={baddr,write_strobe}) && wvalid;
	assign rdata_updated=(hitw)?wdata:rdata[hit_way];
	reg from_writeback;
	
	reg [`DL2waysLog2-1:0] flush_way;
	assign doutB=rdata[(flushing&&!waiting)?flush_way:miss_way];
	reg hitw_saved;	
	reg [61:0] hit_count;
	reg [61:0] access_count;
//	reg found_victim;
	reg [2:0] max_rrpv;
	reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] tag_history [`DL2sets-1:0][`VECTOR_SIZE-1:0];
	(* ram_style = "block" *) reg [4:0] timestep_history [`DL2sets-1:0][`VECTOR_SIZE-1:0];
//	integer h;
	reg found_tag_match;
	reg [4:0] last_timestep_for_tag;
	// reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] last_access_tag [`DL2sets-1:0][256];

	optgen_DL2 optgen_DL2_inst (
        .clk(clk), 
        .reset(reset),
        .set(set),
        .curr_timestep(curr_timestep),
        .last_timestep(last_timestep_for_tag),
        .is_reuse(is_reuse),
		.access(access),
		// .pc(access_pc),
        .should_cache(should_cache)
    );

    hawkeye_predictor_DL2 predictor_DL2_inst (
        .clk(clk), 
        .reset(reset),
        .pc(access_pc),
        .train_up(train_up),
        .train_down(train_down),
		.access(access),
        .prediction(prediction)
    );

	
	always @( posedge clk ) begin
		if (reset) begin
			for (i=0; i<`DL2sets; i=i+1) begin
				dirty[i]<=0;
				valid[i]<=0;
				for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin
                    rrpv[i][j_] <= 3'b111;
                end
			end
			en_pending<=0; we_pending<=0;
			roffset<=0;	
			writethrough_block<=0;	wvalid<=0; wtag<=0; baddr<=0;
			writeback<=0; waiting<=0; waiting_en<=0; waiting_en_strobe<=0;
			
			flush_out<=0; flushing<=0; read_once<=0; from_writeback<=0; 
			read_strobe<=0; write_strobe<=0; doutBstrobe<=0;flush_way<=0;

			hit_count<=0; access_count<=0; 
			train_up <= 0;
            train_down <= 0;

            for (i = 0; i < `DL2sets; i = i + 1) begin
                for (k = 0; k < `VECTOR_SIZE; k = k + 1) begin
                    tag_history[i][k] = 0;
					timestep_history[i][k] = 0;
                end
            end

		end else begin

			we_local <=0; we_pending<=0; ready<=0;
			weB<=0; enB<=0; flush_out<=0; 

			if (flush_in) begin flushing<=1; end
			
			last_set<=set; 
			
			if (en) roffset<=addr[(`DL2block_Log2-`DL2subblocks_Log2-3)-1:(`VLEN_Log2-3)];
			access_pc <= pc_in;
		
			if (access) begin
				// $display("L1 train_up: %d train_down %d prediction %d train_up_count: %d train_down_count %d", train_up, train_down, prediction, train_up_count, train_down_count);
				access_count<=access_count+1;
				// $display("last_access_timestep %d", last_access_timestep[set][tag]);
				if (`DEB)$display("DL2 Access hit %d set %d", hit, set);
                hit = 0;
                miss = 1;
                candidate = 0;
                
                for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin
                    if ((tag_array[set][j_] == tag) && valid[set][j_]) begin
                        hit = 1;
                        miss = 0;
                        candidate = j_;
                    end
                end

                if (!hit) begin
                        max_rrpv = 0;
                        for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin
                            if (rrpv[set][j_] >= max_rrpv) begin
                                max_rrpv = rrpv[set][j_];
                                candidate = j_;
                            end
						end
                end

                if (should_cache) begin
					train_up <= 1;
					// $display("DL2: train_up");
				end else begin
					train_down <= 1;
					// $display("DL2: train_down");
				end

                if (is_sampled_set) begin
					
					found_tag_match = 0;
					is_reuse = 0;
					curr_timestep = curr_timestep + 1;
					last_timestep_for_tag = 0;

					for (j_ = 0; j_ < `VECTOR_SIZE; j_ = j_ + 1) begin
						if (tag_history[set][j_] == tag && !found_tag_match) begin
							found_tag_match = 1;
							is_reuse = 1;
							last_timestep_for_tag = timestep_history[set][j_];
							timestep_history[set][j_] = curr_timestep;
						end
					end

					if (!found_tag_match) begin
						for (j_ = 0; j_ < `VECTOR_SIZE-1; j_ = j_ + 1) begin
							tag_history[set][j_] = tag_history[set][j_+1];
							timestep_history[set][j_] = timestep_history[set][j_+1];
						end
						tag_history[set][`VECTOR_SIZE-1] = tag;
						timestep_history[set][`VECTOR_SIZE-1] = curr_timestep;
					end

					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " tag_history: ", tag_history[set][`VECTOR_SIZE-1]," timestep_history: ", timestep_history[set][`VECTOR_SIZE-1], " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag);
					
				end

				if (hit) begin
					hit_count<=hit_count+1;
					// hit_rate<=(hit_count*100)/access_count;
					// $display("L2 hit_count %d, access_count %d",hit_count, access_count);
                    
					if (prediction > 4) begin
                        rrpv[set][candidate] <= 3'b111; 
                    end else begin
                        rrpv[set][candidate] <= 3'b000; 
                    end


					if (`DEB)$display("hit set %d tag %h way %h",set, tag, candidate);
					if (en) ready<=1;

					read_strobe<=access_strobe; // needed for rdata_updated
					if (we) begin 

						we_pending<=1;	
						we_pending_v=addr[(`DL2block_Log2-`DL2subblocks_Log2-3)-1:(`VLEN_Log2-3)];

						we_pending_data=din;
						wtag_next=tag; bset=set;
						
						dirty[set][candidate]<=1;											
						write_strobe<=access_strobe;
						//read_strobe<=access_strobe;
						read_strobe<=0;
						if (`DEB)$display("L2write %h at %h was_dirty %h",din,addr, dirty[set][candidate]);					
						
					end	
					hit_way<=candidate;
					hitw_saved<=hitw;
					
				end

				if (miss) begin

					if (prediction > 4) begin
                        
                        rrpv[set][candidate] <= 3'b111;
                        
                    end else begin
                        // Cache-averse RRIP = 7
						rrpv[set][candidate] <= 3'b000;

						for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin

						if (j_ != candidate && rrpv[set][j_] < 3'b110) begin 
							rrpv[set][j_] <= rrpv[set][j_] + 1;
						end
                        
                        end
                    end

					if (`DEB)$display("miss set %d tag %h way %d",set, tag, candidate);
					en_pending_addr<={tag,set,{(`DL2block_Log2-3){1'b0}}};
					//baddr<=set;
					en_pending_write<=addr[(`DL2block_Log2-`DL2subblocks_Log2-3)-1:(`VLEN_Log2-3)];//we<<(addr[(`VLEN_Log2-3)-1:2]*4);	
					//if (we) 
					//	$display("write %h at %h tag %h way %d", din, addr,tag, candidate);	
						
					we_pending_data=din;//<<(addr[(`VLEN_Log2-3)-1:2]*32);				
					
					// for writeback
					read_once<=0; 					
					doutBstrobe<=0;
								
					if (dirty[set][candidate]&&valid[set][candidate]) begin
						if (`DEB)$display("was dirty");
						writeback<=1;
						read_strobe<=0;
						
						from_writeback<=1;
						addrB<={tag_array[set][candidate],set,{(`DL2block_Log2-3){1'b0}}};		
					end else begin 
						from_writeback<=0;
						enB<=accR&&accW; addrB<={tag,set,{(`DL2block_Log2-3){1'b0}}}; //waddrh<=addr;
						en_pending<=!(accR&&accW);					
					end
					
					valid[set][candidate]<=1;
					dirty[set][candidate]<=we;
					tag_array[set][candidate]<=tag;
					
					waiting<=1;
					waiting_en<=en; waiting_en_strobe<=access_strobe;
					wtag<=tag; baddr<=set; write_strobe<=0;
					
					miss_way<=candidate;			
				end
			end


			if (we_pending  
				) begin
				we_local[hit_way]<=1; wvalid<=1; wtag<=wtag_next; baddr<=bset;
				for (i=0; i<`DL2block/`DL2subblocks/`VLEN; i=i+1) 
					wdata[(i+1)*`VLEN-1-:`VLEN]<= we_pending_v==i?
						we_pending_data:(
						 (hitw_saved)?wdata[(i+1)*`VLEN-1-:`VLEN]:
						 rdata[hit_way][(i+1)*`VLEN-1-:`VLEN]);
	 
				if (`DEB)$display("L2write2 %h at %h was_dirty %b (last_set==set) %d (baddr==set) %d ",rdata_updated,{bset,candidate}, dirty[set],(last_set==set),(baddr==set));				
			end
			
			
			
			if (writeback) begin 	
							
				if (accW || (read_strobe!=0))	begin
					
					weB<=1; 
					
					doutBstrobe<=read_strobe; read_strobe<=read_strobe+1;	
					flush_way<=writethrough_way;
								
					if (read_strobe==`DL2subblocks-1) begin
						writeback<=0; 
														
						if (flushing && !waiting) begin
							dirty[writethrough_set][writethrough_way]<=0;
							writethrough_block<=writethrough_block+1;
							if (`DEB)$display("writethrough_block %d set %d way %d ", writethrough_block, writethrough_set,writethrough_way);	
						end	else begin
							en_pending<=1;
						end
								
					end				
				end					
								
			end else if (flushing && accW && !waiting) begin
			
				addrB<={tag_array[writethrough_set][writethrough_way],writethrough_set,{(`DL2block_Log2-3){1'b0}}};
				read_strobe<=0;		
				if (dirty[writethrough_set][writethrough_way]&&valid[writethrough_set][writethrough_way]) begin	
					writeback<=1;
				end else begin
					writeback<=0;
					writethrough_block<=writethrough_block+1;
					if (`DEB)$display("writethrough_block %d set %d way %d ", writethrough_block, writethrough_set,writethrough_way);	
				end
				
				
				if (writethrough_block[`DL2setsLog2+`DL2waysLog2+1-1]==1) begin
					flush_out<=1;		
					writethrough_block<=0;				
				end												

			end 
			
			if (flush_out) begin flushing<=0; flush_out<=0; end 
			
			if (en_pending && accR && (accW||from_writeback)) begin
				enB<=1; addrB<=en_pending_addr;
				en_pending<=0;
			end
			
			
			if (dreadyB) begin				
				write_strobe<=dinBstrobe;
				if (dinBstrobe==`DL2subblocks-1) begin
					waiting<=0; waiting_en<=0; 
				end

				we_local[miss_way]<=1; wvalid<=1;
				
				for (i=0; i<`DL2block/`DL2subblocks/`VLEN; i=i+1)
					wdata[`VLEN*(i+1)-1-:`VLEN]<= ((en_pending_write==i) &&
					 (!waiting_en) && (dinBstrobe==waiting_en_strobe)
					 )?
						we_pending_data: dinB[`VLEN*(i+1)-1-:`VLEN];
			end
		end		
	end
	
	
	always @(*) begin
		for (i=0; i<`DL2block/`DL2subblocks/`VLEN; i=i+1)begin
			if (roffset==i) dout=load_from_prev_lev?
				dinB[`VLEN*(i+1)-1-:`VLEN]:rdata_updated[`VLEN*(i+1)-1-:`VLEN];
		end	
	end
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, 
		addr, en, we, din, dout, dready, accepting,
		addrB, enB, weB, dinB, doutB, dreadyB, accR,en_pending_write,
		accepting,accW,en_pending,writeback,we_local,we_pending,weB,enB,hitw,hitw_saved,
		dready,miss,hit,we,en,ready,waiting,waiting_en, wdata,flushing,we_pending_data,
		read_strobe,write_strobe,access_strobe,dinBstrobe,doutBstrobe,waiting_en_strobe
		);
	end
endmodule // DL2cache

// LLC is unified between IL1 and DL1. This is its arbiter
module DL2cacheU (clk, reset, cycles,
		enI, addrI, doutI, dreadyI,
		addrD, enD, weD, doutD, dinD, dreadyD, acceptingD, flush_in,
		addrB, enB, weB, dinBstrobe, dinB, doutBstrobe, doutB, dreadyB, accR, accW,
		flush_out, pc_in);
	
	input clk, reset;
	input [31:0] cycles;	
	
	input enI;
    input [`IADDR_bits-1:0] addrI;
    output [`VLEN-1:0] doutI;
    output dreadyI;
	
	input [`DADDR_bits-1:0] addrD;	
    input enD;
    input weD;    
    output [`VLEN-1:0] doutD;
    input [`VLEN-1:0] dinD;
    output dreadyD;
    output acceptingD;
 	input flush_in;

	output [`DADDR_bits-1:0] addrB;	
    output enB;
    output weB;   
    input [`DL2subblocks_Log2-1:0] dinBstrobe; 
    input [`DL2block/`DL2subblocks-1:0] dinB;
    output [`DL2subblocks_Log2-1:0] doutBstrobe; 
    output [`DL2block/`DL2subblocks-1:0] doutB;
    input dreadyB;
    input accR;
    input accW;
    output flush_out;
	input [`IADDR_bits-1:0] pc_in;
   
	reg [`DADDR_bits-1:0] addr;	
    reg en;
    reg we;    
    reg [`VLEN-1:0] din;
    wire [`VLEN-1:0] dout;
    wire dready;
    wire accepting;
    
    
    
    DL2cache dl2u (clk, reset, cycles,
    	addr, en, we, din, dout, dready, accepting, flush_in,
		addrB, enB, weB, dinBstrobe, dinB, doutBstrobe, doutB, dreadyB, accR, accW, flush_out, pc_in);
		
	assign doutI = dout;
	assign doutD = dout;
	
	reg pending; reg pendingI;
	assign acceptingD = (!(pending||pendingI||enI||enD||weD));

	

	reg IorD;
	assign dreadyI = (IorD?dready:0);
	assign dreadyD = (IorD?0:dready);
	
	
	reg [`DADDR_bits-1:0] saddr;	
    reg sen;
    reg swe;   
	
	always @( posedge clk ) begin
		if (reset) begin 
			pending<=0; pendingI<=0;
			en<=0; we<=0; addr<=0; IorD<=0; din<=0; sen<=0;swe<=0;saddr<=0;
		end else begin
			en<=0; we<=0;
			
			if (pendingI && accepting) begin 
				en<=1;
				pendingI<=0;
				IorD<=1;
			end
			
			if (enI) begin
				if (`DEB)$display("Irequest",accepting,dready);
				addr<=addrI;
				en<=accepting;
				pendingI<=!(accepting);
				we<=0;
				if (accepting) IorD<=1;
			end 
			
			if (enD||weD) begin			
				if ((enI || !accepting) ) begin
					saddr<=addrD;
					sen<=enD;
					swe<=weD;
					pending<=1;
				end else begin
					addr<=addrD;
					en<=enD;
					we<=weD;
					IorD<=0;
				end
			end
			
			if (pending && !enI && accepting && !pendingI) begin 
				IorD<=0;
				addr<=saddr;
				en<=sen;
				we<=swe;
				pending<=0;
			end
			if (weD) din<=dinD;
		end
	end   
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, en,we,enI, enD, weD, dreadyI, dreadyD,  dready,pending,pendingI);
	end	
endmodule // DL2cacheU


reg [`VLEN-1:0] way [`DL1ways-1:0][`DL1sets-1:0] ;
reg [`VLEN-1:0] rdata [`DL1ways-1:0];
reg [`VLEN-1:0] wdata;
reg [`DL1ways-1:0] we_local; 
reg [`DL1setsLog2-1:0] baddr;

for (j=0;j<`DL1ways;j=j+1) begin   
		always @(posedge clk) begin
			if (we_local[j]) begin
				way[j][baddr]<=wdata;
			end         
			rdata[j]<=way[j][set];
		end
	end





most updated cache with block ram


// In powers of 2 above 1
`define IADDR_bits 21
`define DADDR_bits 30 // >= IADDR_bits

`define DEB 0

`define VLEN 256 
`define VLEN_Log2 $clog2(`VLEN)
// In powers of 2 above 1
`define IL1sets 64

`define DL1sets 16
`define DL1ways 4

`define DL2sets 16
`define DL2ways 4
`define DL2block 16384 // 512-byte
`define DL2subblocks 32

`define IL1setsLog2 $clog2(`IL1sets)
`define DL1setsLog2 $clog2(`DL1sets)
`define DL1waysLog2 $clog2(`DL1ways)

`define DL2setsLog2 $clog2(`DL2sets)
`define DL2waysLog2 $clog2(`DL2ways)
`define DL2block_Log2 $clog2(`DL2block)
`define DL2subblocks_Log2 $clog2(`DL2subblocks)

`define VECTOR_SIZE 16
`define OCC_WIDTH 4

`define SHCT_SIZE 256
`define VECTOR_SIZELog2 $clog2(`VECTOR_SIZE)


module IL1Cache (clk, reset, PC, instr, ready,
	en, PCB, instrB, readyB);
	input clk, reset;
	input [`IADDR_bits-1:0] PC;  
    output reg [31:0] instr;
    output reg ready;
    
    output reg en;
    output reg [`IADDR_bits-1:0] PCB;
    input [`VLEN-1:0] instrB;
    input readyB;

    /*(* ram_style = "distributed" *)*/ reg [`VLEN-1:0] mem [`IL1sets-1:0];
    reg [`IADDR_bits-`IL1setsLog2-`VLEN_Log2+3-1:0] tag_array [`IL1sets-1:0];
    reg valid [`IL1sets-1:0];
    
    wire [`IL1setsLog2-1:0] set; assign set = PC>>(`VLEN_Log2-3);
    wire [`IADDR_bits-`IL1setsLog2-`VLEN_Log2+3-1:0] tag; assign tag = PC>>(`VLEN_Log2-3+`IL1setsLog2);
    
    wire hit; assign hit = valid[set] && (tag_array[set]==tag);
    reg [`VLEN_Log2-5-1:0] roffset; //assign roffset = PC>>2;
    
	reg pending; integer i;  
	
	always @( posedge clk ) begin
		if (reset) begin
			for (i=0; i<`IL1sets; i=i+1) begin
				valid[i]<=0;	
				tag_array[i]<=0;
			end
			pending<=0;	en<=0;

		end else begin

			if (readyB) begin
				mem[set]<=instrB;
				if (`DEB)$display("filling set %d with %h ready %d",set,instrB, ready);
				instr<=instrB[(roffset+1)*32-1-:32];     
			end else begin
				instr<=mem[set][(PC[`VLEN_Log2-5-1+2:2]+1)*32-1-:32];
//$display("non filling");
			end
			
			ready<=hit||readyB;		
			if (`DEB)$display("ihit %d roffset %d %h",hit,roffset,PC);

			en<=0;
			if ((!hit) && (!pending)) begin 
				en<=1;
				pending<=1;
				roffset <= PC>>2;		
				PCB<=PC;
				if (`DEB)$display("requesting %h",PC);
			end
			
			if (readyB) begin
				pending<=0;			
				valid[set]<=1;
				tag_array[set]<=tag;
			end	

		end
	end		
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, 
		PC, instr, ready, en, PCB, instrB, readyB, hit);
	end
endmodule

module optgen_DL1 
(
    input wire clk,
    input wire reset,
    input wire [`DL1setsLog2-1:0] set,
    input wire [4:0] curr_timestep,
    input wire [4:0] last_timestep,
    input wire is_reuse, 
	input wire access,      
    output reg should_cache          
);
    (* ram_style = "block" *) reg [`OCC_WIDTH-1:0] occupancy_vector [`DL1sets-1:0][`VECTOR_SIZE-1:0];
    integer s, q, q_idx;
    
    genvar j;
    reg [`DL1sets-1:0] we_local;
    reg [`VECTOR_SIZELog2-1:0] baddr;
    reg [`OCC_WIDTH-1:0] wdata;
    reg [`OCC_WIDTH-1:0] rdata [`DL1sets-1:0];
    for (j=0;j<`DL1sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_local[j]) begin
				occupancy_vector[j][baddr]<=wdata;
			end         
			rdata[j]<=occupancy_vector[j][set];
		end
	end

    always @(posedge clk) begin
        if (reset) begin
            for (s = 0; s < `DL1sets; s = s + 1)
                for (q = 0; q < `VECTOR_SIZE; q = q + 1)
                    occupancy_vector[s][q] = 0;
            should_cache = 1;
        end 
		if (access) begin
			if (is_reuse) begin
				should_cache = 1;
				occupancy_vector[set][curr_timestep] = 0;
				for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
					if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE]>=`DL1ways) begin
						should_cache = 0;
					end
				end
				if (should_cache) begin
					for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
						if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] < `DL1ways) begin
							occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] = occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] + 1;
							// $display("ov increment");
						end
					end
				end
			end else begin
				should_cache = 0;
				occupancy_vector[set][curr_timestep] = 0;
			end
		end
    end
endmodule

module optgen_DL2 
(
    input wire clk,
    input wire reset,
    input wire [`DL2setsLog2-1:0] set,
    input wire [4:0] curr_timestep,
    input wire [4:0] last_timestep,
    input wire is_reuse,
	input wire access,
	// input wire [`IADDR_bits-1:0] pc,      
    output reg should_cache          
);
    (* ram_style = "block" *) reg [`OCC_WIDTH-1:0] occupancy_vector [`DL2sets-1:0][`VECTOR_SIZE-1:0];
    integer s, q, q_idx;
    
    genvar j;
    reg [`DL2sets-1:0] we_local;
    reg [`VECTOR_SIZELog2-1:0] baddr;
    reg [`OCC_WIDTH-1:0] wdata;
    reg [`OCC_WIDTH-1:0] rdata [`DL2sets-1:0];
    for (j=0;j<`DL2sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_local[j]) begin
				occupancy_vector[j][baddr]<=wdata;
			end         
			rdata[j]<=occupancy_vector[j][set];
		end
	end
	
    always @(posedge clk) begin
        if (reset) begin
            for (s = 0; s < `DL2sets; s = s + 1)
                for (q = 0; q < `VECTOR_SIZE; q = q + 1)
                    occupancy_vector[s][q] = 0;
            should_cache = 1;
//			interval <= 0;
        end 
		if (access) begin
			// $display("last timestep ", last_timestep, " curr_timestep ", curr_timestep, " pc ", pc, " is_reuse ", is_reuse);
			if (is_reuse) begin
				should_cache = 1;
				occupancy_vector[set][curr_timestep] = 0;
				// interval <= curr_timestep - last_timestep;
				// $display("%d", interval);
				// $display("%d %d", last_timestep, curr_timestep);
				for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
					if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE]>=`DL1ways) begin
						should_cache = 0;
						// $display("ov bigger than ways");
					end
				end
				if (should_cache) begin
					
					
					for (q_idx=0; q_idx<`VECTOR_SIZE; q_idx=q_idx+1) begin
						if (occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] < `DL1ways) begin
							occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] = occupancy_vector[set][(curr_timestep-last_timestep+q_idx)% `VECTOR_SIZE] + 1;
							// $display("ov increment");
						end
					end
				end
				// $display("DL2: should_cache: ",should_cache);
			end else begin
				should_cache = 0;
				occupancy_vector[set][curr_timestep] = 0;
				// $display("ov not reused");
			end
			// $display("DL2: should_cache: ",should_cache, " ", pc);
			
		end
		
    end
endmodule

module hawkeye_predictor_DL1 (
    input wire clk,
    input wire reset,
    input wire [`IADDR_bits-1:0] pc,
    input wire train_up,
    input wire train_down,
	input wire access,
    output reg [2:0] prediction
);

    reg [2:0] shct [0:`SHCT_SIZE-1];
    
 

    function [7:0] hash;
		input [`IADDR_bits-1:0] pc;  
		begin
			hash = pc[6:0] ^ pc[13:7] ^ pc[20:14];
		end
	endfunction

    wire [7:0] index;
    assign index = hash(pc);
    integer i;
    always @(posedge clk or posedge reset) begin
	// always @(posedge access) begin
        if (reset) begin
            for (i = 0; i < `SHCT_SIZE; i = i + 1) begin
                shct[i] = 3'b100;
				prediction = shct[i];
			end
        end else if (access) begin
            if (train_up && shct[index] > 3'b000) begin
                shct[index] = shct[index] - 1;
				prediction = shct[index];
				// $display("Train up");
            end
            else if (train_down && shct[index] < 3'b111) begin
                shct[index] = shct[index] + 1;
				prediction = shct[index];
				// $display("Train Down");
            end
			// $display("DL1: prediction: ",prediction, " ", index, " ", pc);
        end
		// $display("DL1: prediction: ",shct[index][2]);
		// 
		// if (access) begin 
		// $display("DL1: prediction: ",shct[index], " ", index, " ", pc);
		// end
    end
    // assign prediction = shct[index];
endmodule

module hawkeye_predictor_DL2 (
    input wire clk,
    input wire reset,
    input wire [`IADDR_bits-1:0] pc,
    input wire train_up,
    input wire train_down,
	input wire access,
    output reg [2:0] prediction
);

    reg [2:0] shct [0:`SHCT_SIZE-1];

    function [7:0] hash;
		input [`IADDR_bits-1:0] pc;  
		begin
			hash = pc[6:0] ^ pc[13:7] ^ pc[20:14];
		end
	endfunction

    wire [7:0] index;
    assign index = hash(pc);
    integer i;
    always @(posedge clk or posedge reset) begin
	// always @(posedge access) begin
        if (reset) begin
            for (i = 0; i < `SHCT_SIZE; i = i + 1) begin
                shct[i] = 3'b100;
				prediction = shct[i];
			end
        end else if (access) begin
            if (train_up && shct[index] > 3'b000) begin
                shct[index] = shct[index] - 1;
				prediction = shct[index];
				// $display("Train up");
            end
            else if (train_down && shct[index] < 3'b111) begin
                shct[index] = shct[index] + 1;
				prediction = shct[index];
				// $display("Train Down");
            end
			// $display("DL2: prediction: ",prediction, " ", index, " ", pc);
        end
		// $display("DL2: prediction: ",shct[index][2]);
		// 
		// if (access) begin 
		// $display("DL2: prediction: ",shct[index], " ", index, " ", pc);
		// end
    end
    // assign prediction = shct[index];
endmodule

module DL1cache (clk, reset,cycles, 
		addr, en, we, din, dout, dready, accepting, flush_in,
		addrB, enB, weB, dinB, doutB, dreadyB, acceptingB, flush_out,pc_in);
	input clk, reset; 
	input[31:0] cycles;
	input [`DADDR_bits-1:0] addr;	
    input en;
    input [`VLEN/8-1:0] we;    
    input [`VLEN-1:0] din;
    output reg [`VLEN-1:0] dout;
    output dready;
    output accepting;
    input flush_in;
    output reg [`DADDR_bits-1:0] addrB;	
    output reg enB;
    output reg weB;    
    input [`VLEN-1:0] dinB;
    output reg [`VLEN-1:0] doutB;
    input dreadyB;
    input acceptingB;
    output reg flush_out;
	input [`IADDR_bits-1:0] pc_in;
    
    (* ram_style = "block" *) reg [`VLEN-1:0] way [`DL1ways-1:0][`DL1sets-1:0];
    reg [`VLEN-1:0] rdata [`DL1ways-1:0];
    reg [`VLEN-1:0] wdata;

	(* ram_style = "block" *) reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_array [`DL1sets-1:0][`DL1ways-1:0];
    reg [`DL1ways-1:0] dirty [`DL1sets-1:0];
    reg [`DL1ways-1:0] valid [`DL1sets-1:0];

    reg [2:0] rrpv [`DL1sets-1:0][`DL1ways-1:0];

    wire [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag; 
    assign tag = addr>>(`DL1setsLog2+(`VLEN_Log2-3));
    
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] wtag ;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] wtag_next; reg wvalid;
        
    wire access; assign access = (en||(we!=0));    
   
    reg waiting; reg waiting_en;
    reg flushing; 
    reg [`DL1setsLog2+`DL1waysLog2+1-1:0] writethrough_block;
    
    wire [`DL1setsLog2-1:0] writethrough_set; assign writethrough_set = writethrough_block[`DL1setsLog2+`DL1waysLog2-1:`DL1waysLog2];
    wire [`DL1waysLog2-1:0] writethrough_way; assign writethrough_way = writethrough_block[`DL1waysLog2-1:0];
    
    wire [`DL1setsLog2-1:0] set; assign set = (flushing && !waiting)?writethrough_set:(addr>>(`VLEN_Log2-3)); // modulo implied
    //reg [`DL1setsLog2-1:0] from_auto_wt_set;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_real; 
    reg [`DL1setsLog2-1:0] set_real; 
    always @(*) begin 
    	if (reset) begin 
    		tag_real=0;set_real=0;
    	end else begin
    		if (access) begin     			
    			tag_real=tag; set_real=set;
    		end
    	end
    end
    
    reg [`DL1ways-1:0] we_local; reg [`DL1setsLog2-1:0] baddr;
    reg [`DL1setsLog2-1:0] bset;
    
    reg [`DADDR_bits-1:0] writeback_addr;
		
    reg hit;  
    reg miss; 
    reg [`DL1waysLog2-1:0] candidate; //reg [`DL1waysLog2-1:0] last_candidate;
            
    genvar j; integer j_;
    
//    reg zero_found;

	// reg [4:0] last_access_timestep [`DL1sets-1:0][256]; 
    reg [4:0] curr_timestep;  
    reg [`IADDR_bits-1:0] access_pc;

    wire is_sampled_set = 1'b1; 
    reg is_reuse;
    wire should_cache;
    wire [2:0] prediction;
    reg train_up, train_down;
    

    for (j=0;j<`DL1ways;j=j+1) begin   
   	
		always @(posedge clk) begin
		
			if (we_local[j]) begin
				way[j][baddr]<=wdata;

				if (`DEB)$display("...storing1 %h at set %d addr %h",wdata, baddr,{wtag,baddr});				
			end         
			rdata[j]<=way[j][set];
			if (`DEB)if (en&&hit) $display("...loading %h from set %d way %d addr %h", way[j][set], j, set, addr);
		
		end
	end
	reg [`DL1sets-1:0] we_localt;
    reg [`DL1waysLog2-1:0] baddrt;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] wdatat;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] rdatat [`DL1sets-1:0];

	for (j=0;j<`DL1sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_localt[j]) begin
				tag_array[j][baddrt]<=wdatat;				
			end         
			rdatat[j]<=tag_array[j][set];
		end
	end
		
	reg we_pending; reg[`VLEN/8-1:0] we_pending_v; reg [`VLEN-1:0] we_pending_data;
	reg en_pending; reg [`VLEN/8-1:0] en_pending_write; reg [`DADDR_bits-1:0] en_pending_addr;
	reg writeback;

	integer i,k;
	
	assign accepting = !(we_pending||we||en||(waiting)||flushing);	
	
	reg [`DL1setsLog2-1:0] last_set; reg we_local_prev;	
	reg [(`VLEN_Log2-3)-2-1:0] roffset;

	reg ready;
	wire load_from_prev_lev=dreadyB && waiting_en;//(en_pending_write==0);
	assign dready=ready||load_from_prev_lev;
	
	reg read_once;
	reg [`DL1waysLog2-1:0] hit_way;
	reg [`DL1waysLog2-1:0] miss_way;
	
	wire [`VLEN-1:0] rdata_updated;
	wire hitw;  
    assign hitw = (wtag==tag_real) && (set_real==baddr) && wvalid;
	
	assign rdata_updated=(hitw)?wdata:rdata[hit_way];
	reg full_line_write_miss;
	reg [61:0] hit_count;
	reg [61:0] access_count;
	reg [2:0] max_rrpv;
	
	(* ram_style = "block" *) reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_history [`DL1sets-1:0][`VECTOR_SIZE-1:0];
	(* ram_style = "block" *) reg [4:0] timestep_history [`DL1sets-1:0][`VECTOR_SIZE-1:0];
	reg found_tag_match;
	reg [4:0] last_timestep_for_tag;
    
    reg [`DL1sets-1:0] we_localth;
    reg [`VECTOR_SIZELog2-1:0] baddrth;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] wdatath;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] rdatath [`DL1sets-1:0];
    for (j=0;j<`DL1sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_localth[j]) begin
				tag_history[j][baddrth]<=wdatath;
			end         
			rdatath[j]<=tag_history[j][set];
		end
	end
	
	reg [`DL1sets-1:0] we_local_time;
    reg [`VECTOR_SIZELog2-1:0] baddr_time;
    reg [4:0] wdata_time;
    reg [4:0] rdata_time [`DL1sets-1:0];
    for (j=0;j<`DL1sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_local_time[j]) begin
				tag_history[j][baddr_time]<=wdata_time;
			end         
			rdata_time[j]<=tag_history[j][set];
		end
	end
	
	
	

	optgen_DL1 optgen_DL1_inst (
        .clk(clk), 
        .reset(reset),
        .set(set),
        .curr_timestep(curr_timestep),
        .last_timestep(last_timestep_for_tag),
        .is_reuse(is_reuse),
		.access(access),
		// .pc(access_pc),
        .should_cache(should_cache)
    );

    hawkeye_predictor_DL1 predictor_DL1_inst (
        .clk(clk), 
        .reset(reset),
        .pc(access_pc),
        .train_up(train_up),
        .train_down(train_down),
		.access(access),
        .prediction(prediction)
    );

	always @( posedge clk ) begin
		if (reset) begin

            for (i=0; i<`DL1sets; i=i+1) begin				  
                dirty[i]<=0;
                valid[i]<=0;
                for (j_ = 0; j_ < `DL1ways; j_ = j_ + 1) begin
                    rrpv[i][j_] <= 3'b111;
                end
            end

			en_pending<=0;
			roffset<=0;	
			writethrough_block<=0; wtag<=0; wvalid<=0; we_pending<=0; waiting_en<=0;
			writeback<=0;	waiting<=0; waiting_en<=0; read_once<=0; baddr<=0;
			
			flush_out<=0; flushing<=0; full_line_write_miss<=0;
			
			hit_count<=0; access_count<=0; 
			
            train_up <= 0;
            train_down <= 0;

			

            
            for (i = 0; i < `DL1sets; i = i + 1) begin
                for (k = 0; k < `VECTOR_SIZE; k = k + 1) begin
                    tag_history[i][k] = 0;
					timestep_history[i][k] = 0;
                end
            end
		end else begin
            

			we_local <=0; we_pending<=0; ready<=0;
			weB<=0; enB<=0;
			
			if (flush_in) begin flushing<=1; end
			
			last_set<=set; 
			
			if (en) roffset<=addr[(`VLEN_Log2-3)-1:2];						
			
            access_pc <= pc_in; 
			// $display("access", access);
			
			if (access) begin
				// $display("L1 train_up: %d train_down %d prediction %d train_up_count: %d train_down_count %d", train_up, train_down, prediction, train_up_count, train_down_count);
				access_count<=access_count+1;
                
				if (`DEB)$display("DL1 Access hit %d set %d", hit, set);
                hit = 0;
                miss = 1;
                candidate = 0;
                
                for (j_ = 0; j_ < `DL1ways; j_ = j_ + 1) begin
                    if ((tag_array[set][j_] == tag) && valid[set][j_]) begin
                        hit = 1;
                        miss = 0;
                        candidate = j_;
                    end
                end

                if (!hit) begin
                        max_rrpv = 0;
                        for (j_ = 0; j_ < `DL1ways; j_ = j_ + 1) begin
                            if (rrpv[set][j_] >= max_rrpv) begin
                                max_rrpv = rrpv[set][j_];
                                candidate = j_;
                            end
						end
                end

                if (should_cache) begin
					train_up <= 1;
					// $display("DL1: train_up");
				end else begin
					train_down <= 1;
					// $display("DL1: train_down");
				end

                if (is_sampled_set) begin
				
					found_tag_match = 0;
					is_reuse = 0;
					curr_timestep = curr_timestep + 1;
					last_timestep_for_tag = 0;

					for (j_ = 0; j_ < `VECTOR_SIZE; j_ = j_ + 1) begin
						if (tag_history[set][j_] == tag && !found_tag_match) begin
							found_tag_match = 1;
							is_reuse = 1;
							last_timestep_for_tag = timestep_history[set][j_];
							timestep_history[set][j_] = curr_timestep;
						end
					end

					if (!found_tag_match) begin
						for (j_ = 0; j_ < `VECTOR_SIZE-1; j_ = j_ + 1) begin
							tag_history[set][j_] = tag_history[set][j_+1];
							timestep_history[set][j_] = timestep_history[set][j_+1];
						end
						tag_history[set][`VECTOR_SIZE-1] = tag;
						timestep_history[set][`VECTOR_SIZE-1] = curr_timestep;
					end

					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " tag_history: ", tag_history[set][`VECTOR_SIZE-1]," timestep_history: ", timestep_history[set][`VECTOR_SIZE-1], " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag);
					
				end

                if (hit) begin
                    hit_count<=hit_count+1;
                    // hit_rate<=(hit_count*100)/access_count;
                    // $display("L1 hit_count %d, access_count %d",hit_count, access_count);

                    if (prediction > 4) begin
                        rrpv[set][candidate] <= 3'b111; 
                    end else begin
                        rrpv[set][candidate] <= 3'b000; 
                    end

                    // $display("hit1 set %d tag %h way %h",set, tag, candidate);
                    if (en) ready<=1;
                    
                    if (we!=0) begin 

                        we_pending<=(last_set!=set) && !hitw;
                                                        
                        we_pending_v=we<<(addr[(`VLEN_Log2-3)-1:2]*4);	
                        wtag_next=tag;bset=set;

                        we_pending_data=din<<(addr[(`VLEN_Log2-3)-1:2]*32);
                        
                        dirty[set][candidate]<=1;											
                        
                        
                        if (`DEB)$display("writeL1 %h at %h was_dirty %h we %h off %d",din,addr, dirty[set][candidate],we, addr[(`VLEN_Log2-3)-1:2]);
                    end	
                    hit_way=candidate;
			    end

                if (miss) begin
					
                    if (prediction > 4) begin
                        
                        rrpv[set][candidate] <= 3'b111;
                        
                    end else begin
                        // Cache-averse RRIP = 7
						rrpv[set][candidate] <= 3'b000;

						for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin

						if (j_ != candidate && rrpv[set][j_] < 3'b110) begin 
							rrpv[set][j_] <= rrpv[set][j_] + 1;
						end
                        
                        end
                    end

                    if (`DEB)$display("miss set %d tag %h way %d",set, tag, candidate);
                    en_pending_addr<={tag,set,{(`VLEN_Log2-3){1'b0}}};

                    en_pending_write<=we<<(addr[(`VLEN_Log2-3)-1:2]*4);	
                    if (`DEB)if (we!=0) 
                        $display("writeL1 %h at %h tag %h way %d", din, addr,tag, candidate);		
                        
                    we_pending_data=din<<(addr[(`VLEN_Log2-3)-1:2]*32);
                                    
                    if (dirty[set][candidate]&&valid[set][candidate]) begin

                        writeback<=1;
                        read_once<=1;

                        addrB<={tag_array[set][candidate],set,{(`VLEN_Log2-3){1'b0}}};		
                    end else begin 
                        enB<=acceptingB; addrB<={tag,set,{(`VLEN_Log2-3){1'b0}}};
                        en_pending<=!acceptingB;					
                    end
                    
                    valid[set][candidate]<=1;
                    dirty[set][candidate]<=we!=0;
                    tag_array[set][candidate]<=tag;
                    // last_pc[set][candidate] <= access_pc;

                    waiting<=1;
                    waiting_en<=en;
                    full_line_write_miss<=0;
                    
                    if((we=={(`VLEN/8){1'b1}})) begin
                        full_line_write_miss<=1;
                        en_pending<=0; enB<=0;
                        waiting<=dirty[set][candidate]&&valid[set][candidate];
                        wdata<= din; 

                        we_local[candidate]<=1; wvalid<=1;

                        if (`DEB)$display("we %h din %h rof %d",we,din, addr[(`VLEN_Log2-3)-1:2]);
                        if (`DEB)$display("STORE_PEND finished %d",cycles+1);

                    end
                        
                    wtag<=tag; baddr<=set;				
                    miss_way<=candidate;

			    end
			end
			
			
			if (we_pending  
				||(hit&&(we!=0)&&((last_set==set)|| hitw))
				) begin
				we_local[hit_way]<=1; wvalid<=1; wtag<=wtag_next; baddr<=bset;
				for (i=0; i<`VLEN/8; i=i+1) 
					wdata[(i+1)*8-1-:8]<= we_pending_v[i]?
						we_pending_data[(i+1)*8-1-:8]:
						 ((hitw)?wdata[(i+1)*8-1-:8]:
						 rdata[hit_way][(i+1)*8-1-:8]
						 );	
				if (`DEB)$display("STORE_PEND finished %d",cycles+1);

			end
		
					
			if (writeback) begin 	
				if (read_once) 
					doutB<=rdata[miss_way];
				read_once<=0;

				if (acceptingB)	begin			
					weB<=1;  
					
					if (`DEB)$display("WritebackL1 %h at %h",read_once?rdata[miss_way]:doutB, addrB);
														
					if (flushing && !waiting) begin
						doutB<=rdata[writethrough_way];
						dirty[set][writethrough_way]<=0;
						writethrough_block<=writethrough_block+1;
						if (`DEB)$display("DL1writethrough_block %d set %d way %d addr %h", writethrough_block, writethrough_set,writethrough_way,addrB);
									
					end	else begin
						en_pending<=!full_line_write_miss;
						if (full_line_write_miss) waiting<=0;						
					end
							
					writeback<=0;				
				end					
								
			end else if (flushing && acceptingB && !waiting) begin
			
				addrB<={tag_array[set][writethrough_way],set,{(`VLEN_Log2-3){1'b0}}};
				if (dirty[set][writethrough_way]&&valid[set][writethrough_way]) begin	
					writeback<=1;
				end else begin
					writeback<=0;
					writethrough_block<=writethrough_block+1;
					if (`DEB)$display("writethrough_block %d set %d way %d ", writethrough_block, writethrough_set,writethrough_way);	
				end
				
				
				if (writethrough_block[`DL1setsLog2+`DL1waysLog2+1-1]==1) begin
					flush_out<=1;	
					writethrough_block<=0;				
				end												
			end 
			
			if (flush_out) begin flushing<=0; flush_out<=0; end 
									
			if (en_pending && acceptingB) begin 
				enB<=1; addrB<=en_pending_addr; 
				en_pending<=0;
			end
			
			if (dreadyB) begin
				waiting<=0; waiting_en<=0;
				if (`DEB)$display("Reading %h from DL2 addr %h",dinB,addrB);
				we_local[miss_way]<=1; wvalid<=1; 
				
				for (i=0; i<`VLEN/8; i=i+1) 
					wdata[(i+1)*8-1-:8]<= en_pending_write[i]?
						we_pending_data[(i+1)*8-1-:8]: dinB[(i+1)*8-1-:8];
				if (`DEB && (en_pending_write!=0))$display("STORE_PEND finished %d",cycles+1);

			end
		end		
	end	
	
	always @(*) begin
		if (roffset==0) // also case of vectors, where we want the entire block
			dout=load_from_prev_lev? dinB: rdata_updated;
		else
			dout=load_from_prev_lev? dinB[32*(roffset+1)-1-:32]:
					rdata_updated[32*(roffset+1)-1-:32];	
	end
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, 
		addr, en, we, din, dout, dready, accepting,
		addrB, enB, weB, dinB, doutB, dreadyB, acceptingB,
		accepting,acceptingB,en_pending,writeback,we_local,we_pending,weB,enB,last_set,hitw,
		dready,miss,hit,we,en,ready,waiting,waiting_en, wdata,rdata_updated,wtag,tag,flushing
		);
	end
endmodule // DL1cache

module DL2cache (clk, reset, cycles,
		addr, en, we, din, dout, dready, accepting, flush_in,
		addrB, enB, weB, dinBstrobe, dinB, doutBstrobe, doutB, dreadyB, accR, accW, flush_out, pc_in);
	input clk, reset; 
	input [31:0] cycles;
	input [`DADDR_bits-1:0] addr;	
    input en;
    input we;    
    input [`VLEN-1:0] din;
    output reg [`VLEN-1:0] dout;
    output dready;
    output accepting;
    input flush_in;
    output reg [`DADDR_bits-1:0] addrB;	
    output reg enB;
    output reg /*[`VLEN/8-1:0]*/ weB;    
    input [`DL2subblocks_Log2-1:0] dinBstrobe;
    input [`DL2block/`DL2subblocks-1:0] dinB;
    output reg [`DL2subblocks_Log2-1:0] doutBstrobe;
    output /*reg*/ [`DL2block/`DL2subblocks-1:0] doutB;
    input dreadyB;
    input accR;
    input accW;
    output reg flush_out;
	input [`IADDR_bits-1:0] pc_in;
    
    (* ram_style = "block" *) reg [`DL2block/`DL2subblocks-1:0] way [`DL2ways-1:0][`DL2sets*`DL2subblocks-1:0] ;
    reg [`DL2block/`DL2subblocks-1:0] rdata [`DL2ways-1:0];
    reg [`DL2block/`DL2subblocks-1:0] wdata;

	(* ram_style = "block" *) reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] tag_array [`DL2sets-1:0][`DL2ways-1:0];
    reg [`DL2ways-1:0] dirty [`DL2sets-1:0];
    reg [`DL2ways-1:0] valid [`DL2sets-1:0];
	reg [2:0] rrpv [`DL2sets-1:0][`DL2ways-1:0]; 

    wire [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] tag; 
    assign tag = addr>>(`DL2setsLog2+(`DL2block_Log2-3));
    
    reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] wtag;
    reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] wtag_next; reg wvalid;
    
    wire access; assign access = (en||we);  
   
    reg flushing; reg waiting; reg waiting_en;

    reg [`DL2setsLog2+`DL2waysLog2+1-1:0] writethrough_block;
    wire [`DL2setsLog2-1:0] writethrough_set; assign writethrough_set = writethrough_block[`DL2setsLog2+`DL2waysLog2-1:`DL2waysLog2];
    wire [`DL2waysLog2-1:0] writethrough_way; assign writethrough_way = writethrough_block[`DL2waysLog2-1:0];
        
    wire [`DL2setsLog2-1:0] set; assign set = (addr>>(`DL2block_Log2-3)); // modulo implied
    
    wire [`DL2subblocks_Log2-1:0] access_strobe; 
    reg  [`DL2subblocks_Log2-1:0] read_strobe;
    reg  [`DL2subblocks_Log2-1:0] write_strobe;
    assign access_strobe=addr>>(`DL2block_Log2-`DL2subblocks_Log2-3);
    	
	reg [`DADDR_bits-(`DL2block_Log2-3)-`DL2setsLog2-1:0] tag_real; 
    reg [`DL2setsLog2-1:0] set_real; 
    always @(*) begin 
    	if (reset) begin 
    		tag_real=0;set_real=0;
    	end else begin
    		if (access) begin
    			tag_real=tag; set_real=set;
    		end
    	end
    end
    
    wire [`DL2setsLog2+`DL2subblocks_Log2-1:0] subset; 
	assign subset={	(flushing && !waiting)?writethrough_set:set_real,
				access?access_strobe:read_strobe};
		
    reg [`DL2ways-1:0] we_local; reg [`DL2setsLog2-1:0] baddr;
    reg [`DL2setsLog2-1:0] bset;
    reg [`DADDR_bits-1:0] writeback_addr;
    	
    reg hit;  
    reg miss; 
    reg [`DL2waysLog2-1:0] candidate;
            
    genvar j; integer j_;
    
//    reg zero_found;        


    // reg [4:0] last_access_timestep [`DL2sets-1:0][256]; 
    reg [4:0] curr_timestep; 
    

    // reg [63:0] last_pc [`DL2sets-1:0][`DL2ways-1:0]; 
    reg [`IADDR_bits-1:0] access_pc; 
    

    wire is_sampled_set = 1; 
    reg is_reuse;
    wire should_cache;
    wire prediction;
    reg train_up, train_down;

    for (j=0;j<`DL2ways;j=j+1) begin   
   	
		always @(posedge clk) begin
		
			if (we_local[j]) begin
				way[j][{baddr,write_strobe}]<=wdata;

				if (`DEB)$display("...storing2 %h at set %d addr%h way %d",wdata, baddr,{wtag,baddr,write_strobe,{(`DL2block_Log2-`DL2subblocks_Log2-3){1'b0}}},j);
			end         
			rdata[j]<=way[j][subset];
			if (`DEB)if (en&&hit &&j==candidate) $display("...loading %h from set %d (%d) way %d addr %h tag %h ", way[j][subset], set, subset, j, addr, tag);
 			
		end
	end
	
	reg [`DL2sets-1:0] we_localt;
    reg [`DL2waysLog2-1:0] baddrt;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] wdatat;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] rdatat [`DL2sets-1:0];
//	(* ram_style = "block" *) reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_array [`DL1sets-1:0][`DL1ways-1:0];
	for (j=0;j<`DL2sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_localt[j]) begin
				tag_array[j][baddrt]<=wdatat;				
			end         
			rdatat[j]<=tag_array[j][set];
		end
	end
	
	reg we_pending; reg[`DL2block/`DL2subblocks/`VLEN-1:0] we_pending_v; 
	reg [`VLEN-1:0] we_pending_data;
	
	reg en_pending; reg [`DL2block/`DL2subblocks/`VLEN-1:0] en_pending_write; reg [`DADDR_bits-1:0] en_pending_addr;
	reg writeback; 

	integer i,k;
	
	assign accepting = !(we_pending||we||en||(waiting)||flushing); 
	
	reg [`DL2setsLog2-1:0] last_set; reg we_local_prev;	
	reg [(`DL2block_Log2-3)-(`DL2subblocks_Log2)-(`VLEN_Log2-3)-1:0] roffset;
	
	reg [`DL2subblocks_Log2-1:0] waiting_en_strobe;
	reg ready;
	wire load_from_prev_lev=dreadyB && waiting_en && (waiting_en_strobe==dinBstrobe);	
	
	assign dready=ready||load_from_prev_lev;
	
	reg read_once;
	reg [`DL2waysLog2-1:0] hit_way;
	reg [`DL2waysLog2-1:0] miss_way;
	
	wire [`DL2block-1:0] rdata_updated;
	wire hitw;  assign hitw = (wtag==tag_real) && (subset=={baddr,write_strobe}) && wvalid;
	assign rdata_updated=(hitw)?wdata:rdata[hit_way];
	reg from_writeback;
	
	reg [`DL2waysLog2-1:0] flush_way;
	assign doutB=rdata[(flushing&&!waiting)?flush_way:miss_way];
	reg hitw_saved;	
	reg [61:0] hit_count;
	reg [61:0] access_count;
//	reg found_victim;
	reg [2:0] max_rrpv;
	(* ram_style = "block" *) reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] tag_history [`DL2sets-1:0][`VECTOR_SIZE-1:0];
	(* ram_style = "block" *) reg [4:0] timestep_history [`DL2sets-1:0][`VECTOR_SIZE-1:0];
//	integer h;
	reg found_tag_match;
	reg [4:0] last_timestep_for_tag;
	// reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] last_access_tag [`DL2sets-1:0][256];
	
    reg [`DL2sets-1:0] we_localth;
    reg [`VECTOR_SIZELog2-1:0] baddrth;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] wdatath;
    reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] rdatath [`DL2sets-1:0];
    for (j=0;j<`DL2sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_localth[j]) begin
				tag_history[j][baddrth]<=wdatath;
			end         
			rdatath[j]<=tag_history[j][set];
		end
	end
	
	reg [`DL2sets-1:0] we_local_time;
    reg [`VECTOR_SIZELog2-1:0] baddr_time;
    reg [4:0] wdata_time;
    reg [4:0] rdata_time [`DL2sets-1:0];
    for (j=0;j<`DL2sets;j=j+1) begin   
		always @(posedge clk) begin
			if (we_local_time[j]) begin
				tag_history[j][baddr_time]<=wdata_time;
			end         
			rdata_time[j]<=tag_history[j][set];
		end
	end
	
	optgen_DL2 optgen_DL2_inst (
        .clk(clk), 
        .reset(reset),
        .set(set),
        .curr_timestep(curr_timestep),
        .last_timestep(last_timestep_for_tag),
        .is_reuse(is_reuse),
		.access(access),
		// .pc(access_pc),
        .should_cache(should_cache)
    );

    hawkeye_predictor_DL2 predictor_DL2_inst (
        .clk(clk), 
        .reset(reset),
        .pc(access_pc),
        .train_up(train_up),
        .train_down(train_down),
		.access(access),
        .prediction(prediction)
    );

	
	always @( posedge clk ) begin
		if (reset) begin
			for (i=0; i<`DL2sets; i=i+1) begin
				dirty[i]<=0;
				valid[i]<=0;
				for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin
                    rrpv[i][j_] <= 3'b111;
                end
			end
			en_pending<=0; we_pending<=0;
			roffset<=0;	
			writethrough_block<=0;	wvalid<=0; wtag<=0; baddr<=0;
			writeback<=0; waiting<=0; waiting_en<=0; waiting_en_strobe<=0;
			
			flush_out<=0; flushing<=0; read_once<=0; from_writeback<=0; 
			read_strobe<=0; write_strobe<=0; doutBstrobe<=0;flush_way<=0;

			hit_count<=0; access_count<=0; 
			train_up <= 0;
            train_down <= 0;

            for (i = 0; i < `DL2sets; i = i + 1) begin
                for (k = 0; k < `VECTOR_SIZE; k = k + 1) begin
                    tag_history[i][k] = 0;
					timestep_history[i][k] = 0;
                end
            end

		end else begin

			we_local <=0; we_pending<=0; ready<=0;
			weB<=0; enB<=0; flush_out<=0; 

			if (flush_in) begin flushing<=1; end
			
			last_set<=set; 
			
			if (en) roffset<=addr[(`DL2block_Log2-`DL2subblocks_Log2-3)-1:(`VLEN_Log2-3)];
			access_pc <= pc_in;
		
			if (access) begin
				// $display("L1 train_up: %d train_down %d prediction %d train_up_count: %d train_down_count %d", train_up, train_down, prediction, train_up_count, train_down_count);
				access_count<=access_count+1;
				// $display("last_access_timestep %d", last_access_timestep[set][tag]);
				if (`DEB)$display("DL2 Access hit %d set %d", hit, set);
                hit = 0;
                miss = 1;
                candidate = 0;
                
                for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin
                    if ((tag_array[set][j_] == tag) && valid[set][j_]) begin
                        hit = 1;
                        miss = 0;
                        candidate = j_;
                    end
                end

                if (!hit) begin
                        max_rrpv = 0;
                        for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin
                            if (rrpv[set][j_] >= max_rrpv) begin
                                max_rrpv = rrpv[set][j_];
                                candidate = j_;
                            end
						end
                end

                if (should_cache) begin
					train_up <= 1;
					// $display("DL2: train_up");
				end else begin
					train_down <= 1;
					// $display("DL2: train_down");
				end

                if (is_sampled_set) begin
					
					found_tag_match = 0;
					is_reuse = 0;
					curr_timestep = curr_timestep + 1;
					last_timestep_for_tag = 0;

					for (j_ = 0; j_ < `VECTOR_SIZE; j_ = j_ + 1) begin
						if (tag_history[set][j_] == tag && !found_tag_match) begin
							found_tag_match = 1;
							is_reuse = 1;
							last_timestep_for_tag = timestep_history[set][j_];
							timestep_history[set][j_] = curr_timestep;
						end
					end

					if (!found_tag_match) begin
						for (j_ = 0; j_ < `VECTOR_SIZE-1; j_ = j_ + 1) begin
							tag_history[set][j_] = tag_history[set][j_+1];
							timestep_history[set][j_] = timestep_history[set][j_+1];
						end
						tag_history[set][`VECTOR_SIZE-1] = tag;
						timestep_history[set][`VECTOR_SIZE-1] = curr_timestep;
					end

					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag, " found_tag_match: ", found_tag_match, " tag_history: ", tag_history[set][`VECTOR_SIZE-1]," timestep_history: ", timestep_history[set][`VECTOR_SIZE-1], " curr_timestep ", curr_timestep, " last_timestep_for_tag ", last_timestep_for_tag);
					// $display("tag: ", tag);
					
				end

				if (hit) begin
					hit_count<=hit_count+1;
					// hit_rate<=(hit_count*100)/access_count;
					// $display("L2 hit_count %d, access_count %d",hit_count, access_count);
                    
					if (prediction > 4) begin
                        rrpv[set][candidate] <= 3'b111; 
                    end else begin
                        rrpv[set][candidate] <= 3'b000; 
                    end


					if (`DEB)$display("hit set %d tag %h way %h",set, tag, candidate);
					if (en) ready<=1;

					read_strobe<=access_strobe; // needed for rdata_updated
					if (we) begin 

						we_pending<=1;	
						we_pending_v=addr[(`DL2block_Log2-`DL2subblocks_Log2-3)-1:(`VLEN_Log2-3)];

						we_pending_data=din;
						wtag_next=tag; bset=set;
						
						dirty[set][candidate]<=1;											
						write_strobe<=access_strobe;
						//read_strobe<=access_strobe;
						read_strobe<=0;
						if (`DEB)$display("L2write %h at %h was_dirty %h",din,addr, dirty[set][candidate]);					
						
					end	
					hit_way<=candidate;
					hitw_saved<=hitw;
					
				end

				if (miss) begin

					if (prediction > 4) begin
                        
                        rrpv[set][candidate] <= 3'b111;
                        
                    end else begin
                        // Cache-averse RRIP = 7
						rrpv[set][candidate] <= 3'b000;

						for (j_ = 0; j_ < `DL2ways; j_ = j_ + 1) begin

						if (j_ != candidate && rrpv[set][j_] < 3'b110) begin 
							rrpv[set][j_] <= rrpv[set][j_] + 1;
						end
                        
                        end
                    end

					if (`DEB)$display("miss set %d tag %h way %d",set, tag, candidate);
					en_pending_addr<={tag,set,{(`DL2block_Log2-3){1'b0}}};
					//baddr<=set;
					en_pending_write<=addr[(`DL2block_Log2-`DL2subblocks_Log2-3)-1:(`VLEN_Log2-3)];//we<<(addr[(`VLEN_Log2-3)-1:2]*4);	
					//if (we) 
					//	$display("write %h at %h tag %h way %d", din, addr,tag, candidate);	
						
					we_pending_data=din;//<<(addr[(`VLEN_Log2-3)-1:2]*32);				
					
					// for writeback
					read_once<=0; 					
					doutBstrobe<=0;
								
					if (dirty[set][candidate]&&valid[set][candidate]) begin
						if (`DEB)$display("was dirty");
						writeback<=1;
						read_strobe<=0;
						
						from_writeback<=1;
						addrB<={tag_array[set][candidate],set,{(`DL2block_Log2-3){1'b0}}};		
					end else begin 
						from_writeback<=0;
						enB<=accR&&accW; addrB<={tag,set,{(`DL2block_Log2-3){1'b0}}}; //waddrh<=addr;
						en_pending<=!(accR&&accW);					
					end
					
					valid[set][candidate]<=1;
					dirty[set][candidate]<=we;
					tag_array[set][candidate]<=tag;
					
					waiting<=1;
					waiting_en<=en; waiting_en_strobe<=access_strobe;
					wtag<=tag; baddr<=set; write_strobe<=0;
					
					miss_way<=candidate;			
				end
			end


			if (we_pending  
				) begin
				we_local[hit_way]<=1; wvalid<=1; wtag<=wtag_next; baddr<=bset;
				for (i=0; i<`DL2block/`DL2subblocks/`VLEN; i=i+1) 
					wdata[(i+1)*`VLEN-1-:`VLEN]<= we_pending_v==i?
						we_pending_data:(
						 (hitw_saved)?wdata[(i+1)*`VLEN-1-:`VLEN]:
						 rdata[hit_way][(i+1)*`VLEN-1-:`VLEN]);
	 
				if (`DEB)$display("L2write2 %h at %h was_dirty %b (last_set==set) %d (baddr==set) %d ",rdata_updated,{bset,candidate}, dirty[set],(last_set==set),(baddr==set));				
			end
			
			
			
			if (writeback) begin 	
							
				if (accW || (read_strobe!=0))	begin
					
					weB<=1; 
					
					doutBstrobe<=read_strobe; read_strobe<=read_strobe+1;	
					flush_way<=writethrough_way;
								
					if (read_strobe==`DL2subblocks-1) begin
						writeback<=0; 
														
						if (flushing && !waiting) begin
							dirty[writethrough_set][writethrough_way]<=0;
							writethrough_block<=writethrough_block+1;
							if (`DEB)$display("writethrough_block %d set %d way %d ", writethrough_block, writethrough_set,writethrough_way);	
						end	else begin
							en_pending<=1;
						end
								
					end				
				end					
								
			end else if (flushing && accW && !waiting) begin
			
				addrB<={tag_array[writethrough_set][writethrough_way],writethrough_set,{(`DL2block_Log2-3){1'b0}}};
				read_strobe<=0;		
				if (dirty[writethrough_set][writethrough_way]&&valid[writethrough_set][writethrough_way]) begin	
					writeback<=1;
				end else begin
					writeback<=0;
					writethrough_block<=writethrough_block+1;
					if (`DEB)$display("writethrough_block %d set %d way %d ", writethrough_block, writethrough_set,writethrough_way);	
				end
				
				
				if (writethrough_block[`DL2setsLog2+`DL2waysLog2+1-1]==1) begin
					flush_out<=1;		
					writethrough_block<=0;				
				end												

			end 
			
			if (flush_out) begin flushing<=0; flush_out<=0; end 
			
			if (en_pending && accR && (accW||from_writeback)) begin
				enB<=1; addrB<=en_pending_addr;
				en_pending<=0;
			end
			
			
			if (dreadyB) begin				
				write_strobe<=dinBstrobe;
				if (dinBstrobe==`DL2subblocks-1) begin
					waiting<=0; waiting_en<=0; 
				end

				we_local[miss_way]<=1; wvalid<=1;
				
				for (i=0; i<`DL2block/`DL2subblocks/`VLEN; i=i+1)
					wdata[`VLEN*(i+1)-1-:`VLEN]<= ((en_pending_write==i) &&
					 (!waiting_en) && (dinBstrobe==waiting_en_strobe)
					 )?
						we_pending_data: dinB[`VLEN*(i+1)-1-:`VLEN];
			end
		end		
	end
	
	
	always @(*) begin
		for (i=0; i<`DL2block/`DL2subblocks/`VLEN; i=i+1)begin
			if (roffset==i) dout=load_from_prev_lev?
				dinB[`VLEN*(i+1)-1-:`VLEN]:rdata_updated[`VLEN*(i+1)-1-:`VLEN];
		end	
	end
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, 
		addr, en, we, din, dout, dready, accepting,
		addrB, enB, weB, dinB, doutB, dreadyB, accR,en_pending_write,
		accepting,accW,en_pending,writeback,we_local,we_pending,weB,enB,hitw,hitw_saved,
		dready,miss,hit,we,en,ready,waiting,waiting_en, wdata,flushing,we_pending_data,
		read_strobe,write_strobe,access_strobe,dinBstrobe,doutBstrobe,waiting_en_strobe
		);
	end
endmodule // DL2cache

// LLC is unified between IL1 and DL1. This is its arbiter
module DL2cacheU (clk, reset, cycles,
		enI, addrI, doutI, dreadyI,
		addrD, enD, weD, doutD, dinD, dreadyD, acceptingD, flush_in,
		addrB, enB, weB, dinBstrobe, dinB, doutBstrobe, doutB, dreadyB, accR, accW,
		flush_out, pc_in);
	
	input clk, reset;
	input [31:0] cycles;	
	
	input enI;
    input [`IADDR_bits-1:0] addrI;
    output [`VLEN-1:0] doutI;
    output dreadyI;
	
	input [`DADDR_bits-1:0] addrD;	
    input enD;
    input weD;    
    output [`VLEN-1:0] doutD;
    input [`VLEN-1:0] dinD;
    output dreadyD;
    output acceptingD;
 	input flush_in;

	output [`DADDR_bits-1:0] addrB;	
    output enB;
    output weB;   
    input [`DL2subblocks_Log2-1:0] dinBstrobe; 
    input [`DL2block/`DL2subblocks-1:0] dinB;
    output [`DL2subblocks_Log2-1:0] doutBstrobe; 
    output [`DL2block/`DL2subblocks-1:0] doutB;
    input dreadyB;
    input accR;
    input accW;
    output flush_out;
	input [`IADDR_bits-1:0] pc_in;
   
	reg [`DADDR_bits-1:0] addr;	
    reg en;
    reg we;    
    reg [`VLEN-1:0] din;
    wire [`VLEN-1:0] dout;
    wire dready;
    wire accepting;
    
    
    
    DL2cache dl2u (clk, reset, cycles,
    	addr, en, we, din, dout, dready, accepting, flush_in,
		addrB, enB, weB, dinBstrobe, dinB, doutBstrobe, doutB, dreadyB, accR, accW, flush_out, pc_in);
		
	assign doutI = dout;
	assign doutD = dout;
	
	reg pending; reg pendingI;
	assign acceptingD = (!(pending||pendingI||enI||enD||weD));

	

	reg IorD;
	assign dreadyI = (IorD?dready:0);
	assign dreadyD = (IorD?0:dready);
	
	
	reg [`DADDR_bits-1:0] saddr;	
    reg sen;
    reg swe;   
	
	always @( posedge clk ) begin
		if (reset) begin 
			pending<=0; pendingI<=0;
			en<=0; we<=0; addr<=0; IorD<=0; din<=0; sen<=0;swe<=0;saddr<=0;
		end else begin
			en<=0; we<=0;
			
			if (pendingI && accepting) begin 
				en<=1;
				pendingI<=0;
				IorD<=1;
			end
			
			if (enI) begin
				if (`DEB)$display("Irequest",accepting,dready);
				addr<=addrI;
				en<=accepting;
				pendingI<=!(accepting);
				we<=0;
				if (accepting) IorD<=1;
			end 
			
			if (enD||weD) begin			
				if ((enI || !accepting) ) begin
					saddr<=addrD;
					sen<=enD;
					swe<=weD;
					pending<=1;
				end else begin
					addr<=addrD;
					en<=enD;
					we<=weD;
					IorD<=0;
				end
			end
			
			if (pending && !enI && accepting && !pendingI) begin 
				IorD<=0;
				addr<=saddr;
				en<=sen;
				we<=swe;
				pending<=0;
			end
			if (weD) din<=dinD;
		end
	end   
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, en,we,enI, enD, weD, dreadyI, dreadyD,  dready,pending,pendingI);
	end	
endmodule // DL2cacheU


/*  Copyright 2021-2024 Philippos Papaphilippou

	You are free to use, learn from, modify and distribute this creative work under 
	  the following conditions:
	1. No code, text, or other elements of this work can be used as an input to models
	  for the purposes of training. Generative A.I. and language models are prohibited
	  from using this work. These do not include search engines and related tools whose
	  main purpose is to index and appropriately point to the original source and author.
	2. It comes under no warranties.
	3. Any modification to the code shall be made available in the style of GNU General
	  Public License v2.0 (GPL-2.0), but published under the same license (not GPL-2.0,
	  and clause 7 still refers to the original copyright holder).
	4. A proper attribution of the author (copyright holder) is required when the work 
	  is used. (If applicable, it would be appreciated to cite the related academic
	  publication that introduced the work.)
	5. It cannot be used for commercial purposes unless specific permission is given by
	  the author. 
	6. A redistribution shall include this license in its entirety.
	7. The author has the right to change this license for future versions of this work,
	  as well as to update and clarify the author's original intentions of the current
	  version, such as with regard to what is considered "fair use" by the author for
	  future entities and technologies.  
*/

`include "cpu.v"
`include "caches.v"
`include "custom.v"

`define StackPointer 32'h0ffffff0
`define StartAddress 32'h00010988

module System(clk, reset, StartAddress, StackPointer,      
        addrD, doutDstrobe, doutD, dinDstrobe, dinD, enD, weD, readyD, accR, accW,
        debug, flush, flushed);
	input clk, reset;	
	
	input [`IADDR_bits-1:0] StartAddress;
    input [`DADDR_bits-1:0] StackPointer;
	        
    output [`DADDR_bits-1:0] addrD;
    output [`DL2subblocks_Log2-1:0] doutDstrobe;
    output [`DL2block/`DL2subblocks-1:0] doutD;
    input [`DL2subblocks_Log2-1:0] dinDstrobe;
    input [`DL2block/`DL2subblocks-1:0] dinD;    
    output enD;
    output weD;
    input readyD;
    input accR;
    input accW;
    
    output [31:0] debug;
    input flush;
    output flushed;      
    
    
    wire [`IADDR_bits-1:0] addrA;
    wire [31:0] doutA;    
    
    wire [`DADDR_bits-1:0] addrB;
    wire [`VLEN-1:0] dinB;
    wire [`VLEN-1:0] doutB;   
     
    wire enB;
    wire [`VLEN/8-1:0] weB;
    wire readyB;
    
    wire acceptingB;
    
	wire readyA;
	wire enI; wire [`IADDR_bits-1:0] addrI; wire [`VLEN-1:0] doutI; wire readyI;
	
	IL1Cache il1 (clk, reset, addrA, doutA, readyA,
		enI, addrI, doutI, readyI);


    wire [`DADDR_bits-1:0] addrC;
    wire [`VLEN-1:0] dinC;
    wire [`VLEN-1:0] doutC;      
    wire enC;
    wire weC;
    wire dreadyC;    
    wire acceptingC;   
        
    wire flush_l2;
    wire [`IADDR_bits-1:0] current_pc; 
    DL1cache dc1(clk, reset, 
		addrB, enB, weB, dinB, doutB, readyB, acceptingB, flush,
		addrC, enC, weC, dinC, doutC, dreadyC, acceptingC, flush_l2, current_pc);     
    
      
    DL2cacheU dc2(clk, reset, 
    	enI, addrI, doutI, readyI,
		addrC, enC, weC, dinC, doutC, dreadyC, acceptingC, flush_l2,
		addrD, enD, weD, dinDstrobe, dinD, doutDstrobe, doutD, readyD, accR, accW, flushed, current_pc); 		
    
    
    Core c0(clk, reset,      	
		addrA, doutA, readyA, StartAddress, StackPointer,
		addrB, doutB, dinB, enB, weB, readyB, acceptingB, current_pc
	);    
   

	assign debug=addrA;
	
endmodule 



/*  Copyright 2021-2024 Philippos Papaphilippou

	You are free to use, learn from, modify and distribute this creative work under 
	  the following conditions:
	1. No code, text, or other elements of this work can be used as an input to models
	  for the purposes of training. Generative A.I. and language models are prohibited
	  from using this work. These do not include search engines and related tools whose
	  main purpose is to index and appropriately point to the original source and author.
	2. It comes under no warranties.
	3. Any modification to the code shall be made available in the style of GNU General
	  Public License v2.0 (GPL-2.0), but published under the same license (not GPL-2.0,
	  and clause 7 still refers to the original copyright holder).
	4. A proper attribution of the author (copyright holder) is required when the work 
	  is used. (If applicable, it would be appreciated to cite the related academic
	  publication that introduced the work.)
	5. It cannot be used for commercial purposes unless specific permission is given by
	  the author. 
	6. A redistribution shall include this license in its entirety.
	7. The author has the right to change this license for future versions of this work,
	  as well as to update and clarify the author's original intentions of the current
	  version, such as with regard to what is considered "fair use" by the author for
	  future entities and technologies.  
*/

//`define XLEN 32 // (not yet other than 32)

`define IADDR_bits 21
`define DADDR_bits 30 // >= IADDR_bits

`define VLEN 256
`define VLEN_Log2 $clog2(`VLEN)

`define NumVregisters 4 // (-1 for register 0, up to 8 -1 registers)

`define Rtype 0 // No immediate
`define Itype 1
`define Stype 2
`define Btype 3
`define Utype 4 // 20-bit immediate
`define Jtype 5

`define DEB 0

// Instruction decode is done asynchronusly as it happens in the same cycle
module IDecoder(instr, iformat, rs1, rs2, rd, immediate, alui_en, auipc_en, load_en, absolute_pc, m_inst, counters, simd_inst, c1_en, c2_en, c3_en);
	input [31:0] instr;
	output reg [2:0] iformat;
	output [4:0] rs1;
	output [4:0] rs2;
	output [4:0] rd;
	output reg [31:0] immediate;
	output reg alui_en;
	output reg auipc_en;
	output reg load_en;
	output reg absolute_pc;
	output reg m_inst;
	output reg counters;
	output reg simd_inst;
	output reg c1_en;
	output reg c2_en;
	output reg c3_en;	
	
	assign rs1 = instr[19:15];
	assign rs2 = instr[24:20];
	assign rd  = instr[11: 7];
	
	always @(*) begin
		case (instr[6:2])
			5'h18: iformat = `Btype; // beq, bne, blt, bge, bltu, bgeu,
			5'h19: iformat = `Itype; // jalr, *
			5'h1b: iformat = `Jtype; // jal,  *
			5'h0d: iformat = `Utype; // lui,  *
			5'h05: iformat = `Utype; // auipc,*
			5'h04: iformat = `Itype; // addi,     slli, slti, sltiu, xori, srli, srai, ori, andi,
			5'h0c: iformat = `Rtype; // add, sub, sll,  slt,  sltu,  xor,  srl,  sra,  or,  and,
									 // mul, mulh, mulhsu, mulhu, div, divu, rem, remu
			5'h00: iformat = `Itype; // lb, lh, lw, lbu, lhu,
			5'h08: iformat = `Stype; // sb, sh, sw,
			5'h03: iformat = `Itype; // fence, fence.i *
			5'h1c: iformat = `Itype; // CSR (rdcycle, rdtime, rdinstret, rdcycleh, rdtimeh, rdinstreth)
			5'h02: iformat = `Rtype; // Custom instruction 0 (c0_lv, c0_sv)
			5'h0A: iformat = `Itype; // Custom instruction 1 (c1 (for c1_merge in the example))	
			5'h16: iformat = `Itype; // Custom instruction 2 (c2 (for c2_sort or c2_prefix in the example))	
			5'h1E: iformat = `Itype; // Custom instruction 2 (c3)		

			default begin 
				iformat =`Rtype; 
			end
		endcase

		
		
		case (iformat)
			//`Rtype:
			`Itype: immediate = {{21{instr[31]}}, instr[30:25], instr[24:21], instr[20]};
			`Stype: immediate = {{21{instr[31]}}, instr[30:25], instr[11:8], instr[7]};
			`Btype: immediate = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
			`Utype: immediate = {instr[31], instr[30:20],instr[19:12], 12'b0};
			`Jtype: immediate = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:25], instr[24:21], 1'b0};
			default: immediate = 0;
		endcase
		
		alui_en=0; auipc_en=0; load_en=0; absolute_pc=0; m_inst=0; counters=0;
		simd_inst=0; c1_en=0; c2_en=0; c3_en=0;
		case (instr[6:2])
			5'h00: load_en=1;
			5'h05: auipc_en=1; // auipc,
			5'h19: begin alui_en=1; absolute_pc=1; end
			5'h1b: begin                           end// jalr,
			5'h04: alui_en=1; // addi,     slli, slti, sltiu, xori, srli, srai, ori, andi,
			5'h0c: begin 
			  alui_en=!instr[25];  // add, sub, sll,  slt,  sltu,  xor,  srl,  sra,  or,  and,		
				m_inst=instr[25]; // mul, mulh, mulhsu, mulhu, div, divu, rem, remu
			end
			5'h1c: counters=1;
			5'h02: begin load_en=instr[14:12]==0; simd_inst=1; end
			5'h0A: begin c1_en=1; simd_inst=1; end
			5'h16: begin c2_en=1; simd_inst=1; end	
			5'h1E: begin c3_en=1; simd_inst=1; end			
			default:; 
		endcase
	end 	
endmodule // IDecoder

// Integer ALU for the base registers
module ALUint(data1, data2, func, result);
	input [31:0] data1;
	input [31:0] data2;
	input [3:0] func;
	output reg [31:0] result;
	
	wire[32:0] sub;  assign sub = data1-data2;
	wire sign_swap = data1[31]!=data2[31];
	
	always @(*) begin
		//if (`DEB)$display("%h func(%h) %h", data1, func, data2);
		case (func[2:0]) 
			3'h0: begin 
				if (func[3]==0)
					result = data1 + data2; // add(i)
				else 
					result = sub; // sub (func 0 with instr[30]==1 & not imm) (subi not available)
				end
			3'h1: result = data1 << data2[4:0];// sll(i)
			3'h2: result = (sub[32]==1)^(sign_swap);// ($signed(data1) < $signed(data2)); // slt(i)
			3'h3: result = (sub[32]==1); // slt(i)u
			3'h4: result = data1 ^  data2; // xor(i)
			3'h5: begin
					if (func[3]==0) 
						result = data1 >> data2[4:0];// srl(i) 
					else
						result = $signed(data1) >>> data2[4:0];// sra(i) (func 5 with instr[30]==1)
				  end
			3'h6: result = data1 | data2; // or(i)
			3'h7: result = data1 & data2;// and(i)	
			default: result=0;	
		endcase
	end
endmodule // ALUint

// ALU for the "M" extension (behaviourial)
module ALUintM(clk, reset, valid, rdin, data1, data2, func, result, rd, ready, accepting);
	input clk, reset, valid;
	input [4:0] rdin;
	input [31:0] data1;
	input [31:0] data2;
	input [3:0] func;	
	output reg [31:0] result;
	output reg [4:0] rd;
	output reg ready;
	output reg accepting;		
	
	reg [63:0] num1; reg [63:0] num2;
	always @(*) begin
		case (func) 
            3'h0: begin num1 ={32'b0,data1}; num2 = {32'b0,data2};  end // mul
            3'h1: begin num1 ={{32{data1[31]}},data1}; num2 = {{32{data2[31]}},data2}; end // mulh
            3'h2: begin num1 ={{32{data1[31]}},data1}; num2 = {32'b0,data2}; end // mulhu
            3'h3: begin num1 ={32'b0,data1}; num2 = {32'b0,data2}; end // mulhsu
			default: begin num1 = data1; num2 = data2; end
		endcase
	end
	
	reg [63:0] product;	
	reg [1:0] clk2;
	reg [2:0] pend_f;
	reg [63:0] data1s; reg [63:0] data2s; reg pend; reg pend2;
	always @(posedge clk) begin
	   if (reset) begin 
	       clk2<=0;
	       pend<=0;
	       pend2=0;
	       pend_f<=0;
	       accepting<=1;
	   end else begin 
	       clk2<=clk2+1;       
	       if (valid) begin 
	       	 //if (`DEB)$display ("ALUintM %h %h",num1,num2,data1,data2 );
	       	 data1s<=num1;   
	      	 data2s<=num2;
	      	 pend2=valid;
	      	 rd<=rdin;
	      	 pend_f<=func;
	      	 accepting<=0;
	      end    
	      
	      if (pend2 && (clk2==2'b01)) begin
	      	pend<=1;
	      	pend2=0;
	      end	
	      	
	      ready<=0;  
	      if (clk2==2'b01 && pend) begin
	      	 pend<=0;
	      	 ready<=1; 	
	      	 accepting<=1;      	 
	      end    
	      
	   end
	end
	
	wire lc = (clk2==2'b11);
	always @(posedge /*clk2[1]*/lc) begin	
		
		product = data1s * data2s;
		case (pend_f) 
			3'h0: result <= product[31:0]; // mul 
			3'h1: result <= product[63:32]; // mulh
			3'h2: result <= product[63:32]; // mulhu
			3'h3: result <= product[63:32]; // mulhsu
			3'h4: result <= $signed(data1s[31:0])/$signed(data2s[31:0]); // div
			3'h5: result <= data1s[31:0]/data2s[31:0]; // divu
			3'h6: result <= $signed(data1s[31:0])%$signed(data2s[31:0]); // rem
			3'h7: result <= data1s[31:0]%data2s[31:0]; // remu
			default: result<=0;	
		endcase
		//if (`DEB)if (valid)$display("ALUM %d %d = %d, func %d", data1, data2, result, func);
	end
endmodule // ALUintM

// Separate ALU for the branch operations
module ALUbranch(data1, data2, func, result);
	input [32:0] data1;
	input [32:0] data2;
	input [2:0] func;
	output reg result;
	
	wire[32:0] sub;  assign sub = data1-data2;
	wire sign_swap = data1[31]!=data2[31];
		
	always @(*) begin
		case (func) 
			3'h0: result = sub==0; // beq
			3'h1: result = sub!=0; // bne					
			3'h4: begin 
				result = (sub[32]==1)^(sign_swap); 
				//if (`DEB)$display("blt> %h %h %h", data1, data2, result); 
			end // blt
			3'h5: begin 
				result = (sub[32]==0)^(sign_swap); 
				//if (`DEB)$display("bge> %h %h %h", data1, data2, result); 
			end // bge
			3'h6: result = sub[32]==1; // bltu
			3'h7:begin 
				result = sub[32]==0; 
				//if (`DEB) $display("bgeu> %h %h %h", data1, data2, result); 
			end // bgeu	
			default: result = 0; 	
		endcase
	end
endmodule // ALUbranch

// Asynchronus PC logic (so that the next PC is available to IL1 beforehand, for no delay on IL1 hits)
module PClogic (clk, reset, next_direction, next_step, PC, PCnext);
	input clk, reset;
	input [1:0] next_direction;
	input [`IADDR_bits-1:0] next_step; // sign-extended
	input [`IADDR_bits-1:0] PC;
	output reg [`IADDR_bits-1:0] PCnext;
	
	always @(*) begin
		begin
			case (next_direction)
				2'h0: PCnext = PC;
				2'h1: PCnext = PC + 4; 
				2'h2: PCnext = PC + next_step;
				2'h3: PCnext = next_step;
			endcase 			
		end		
	end	
endmodule // PClogic


module Core (clk, reset, //cycles, 
		addrA, dinA, readyI, StartAddress, StackPointer,
		addrB, dinB, doutB, enB, weB, readyB, accepting, current_pc
		//debug
		);
		
	input clk, reset; 

	//output [31:0] cycles; // carry cycle count only for debugging, hence the 32-bit limit
	
	output [`IADDR_bits-1:0] addrA;
    input wire [32-1:0] dinA;
    input wire readyI;
    
    input wire [`IADDR_bits-1:0] StartAddress;
    input wire [`DADDR_bits-1:0] StackPointer;
    
    output reg [`DADDR_bits-1:0] addrB;
    input wire [`VLEN-1:0] dinB;
    output reg [`VLEN-1:0] doutB;
    output reg enB;

    output reg [`VLEN/8-1:0] weB;

    input readyB; input accepting;    
//	output debug;
	output reg [`IADDR_bits-1:0] current_pc;
	
	reg [48-1:0] cycle_counter; reg [48-1:0] instr_counter;
	
	reg [`IADDR_bits-1:0] PC; wire [`IADDR_bits-1:0] PCnext; wire [31:0] instr; reg halt;
	reg [31:0] reg_file [31:0]; assign debug=halt;//PC;
	wire [1:0] next_direction;
	wire [`IADDR_bits-1:0] next_step; 	
	
	wire [2:0] func3; assign func3=instr[14:12];
	
	PClogic pcl(clk, reset, next_direction, next_step, PC, PCnext);
	
	assign addrA = PCnext;
	assign instr = dinA; 
			
	wire  alui_enable, auipc_enable, load_enable, absolute_pc, m_inst;	
	wire [2:0] iformat; wire [31:0] immediate;
	wire [4:0] rs1; wire [4:0] rs2; wire [4:0] rd; wire counters;
	wire simd_inst; wire c1_en, c2_en, c3_en;
	
	wire [`DADDR_bits-1:0] daddr; assign daddr=reg_file[rs1]+(simd_inst?reg_file[rs2]:immediate);
	
	IDecoder ide (instr, iformat, rs1, rs2, rd, immediate, alui_enable, auipc_enable, load_enable, absolute_pc, m_inst, counters, simd_inst, c1_en, c2_en, c3_en);	
	
	// Logic for deciding next PC behaviour, according to the instruction type (iformat), 
	// ALU branch result (branch_take), and when there is a stall (halt) etc.
	wire branch_take; wire [31:0] alu_dst;	
	wire dir_bit1; assign dir_bit1 = absolute_pc || ((iformat==`Jtype) || (branch_take && (iformat==`Btype)));
	wire dir_bit0; assign dir_bit0 = (iformat!=`Jtype) && !(branch_take && (iformat==`Btype));
	assign next_direction = {dir_bit1, dir_bit0}&{!(halt|reset), !(halt|reset)};	
	assign next_step= absolute_pc?{daddr[`DADDR_bits-1:1],1'b0}:immediate;
	
	wire [`IADDR_bits-1:0] auipc; assign auipc = PC+immediate;
	wire [`IADDR_bits-1:0] pc4; assign pc4=PC+4;
	
	// Select the appropriate operands for ALUint, such as according to if it adds the immediate field
	wire [31:0] alu_rs1; assign alu_rs1 = reg_file[rs1];
	wire [31:0] alu_rs2; assign alu_rs2 = (iformat==`Itype || iformat==`Stype)?immediate:reg_file[rs2];
	wire [3:0] alu_func; assign alu_func = {instr[30]&&!(iformat==`Itype&&func3==0),func3};
	
	ALUint    alu0 (alu_rs1, alu_rs2, alu_func, alu_dst);		
	ALUbranch alu1 (alu_rs1, alu_rs2, func3, branch_take);
	
	// Separate ALU for the "M" instruction
	wire [4:0] m_rd; wire m_ready; wire [31:0] m_res; wire m_acc;
	ALUintM   alu2 (clk, reset, m_inst&!halt, rd, alu_rs1, alu_rs2, alu_func, m_res, m_rd, m_ready, m_acc);
	
	integer i;	
	reg was_en2, readok;
	
	// 4 outstanding reads (must be in order) (but not very pipelined at the moment)
	reg [1:0] read_rq_i_in;
	reg [2+3-1:0] read_rq_filter [3:0];	
	reg [1+4:0] read_rq_reg [3:0]; // one more bit to say if vector
	reg [1:0] read_rq_i_out;

	wire [4:0] rd_read; assign rd_read   = read_rq_reg[read_rq_i_out];
	wire rd_read_v;     assign rd_read_v = read_rq_reg[read_rq_i_out][5];
	wire [2+3-1:0] rd_filter; assign rd_filter = read_rq_filter[read_rq_i_out];
	
	reg reg_pend [31:0];
		
	reg [`VLEN-1:0] reg_file_v [`NumVregisters-1:0]; reg reg_pend_v [`NumVregisters-1:0]; 
	
	wire [2:0] vrs1; assign vrs1 = instr[31:29];
	wire [2:0] vrd1; assign vrd1 = instr[28:26];
	wire [2:0] vrs2; assign vrs2 = instr[25:23];
	wire [2:0] vrd2; assign vrd2 = instr[22:20];	
	
	
	wire fetch_wait; 
	assign fetch_wait = ((!accepting) || ((read_rq_i_in+1)%4==read_rq_i_out));
	
	wire c1_not_accepting; // very specific to merge, can be removed for others (but also below)
	
	// Stall logic, according to the instruction type, as there are different data dependancy checks
	always @(*) begin

		case (iformat)
			`Rtype: halt =!readyI|| reg_pend[rs1] || reg_pend[rs2] ||reg_pend[rd] || (m_inst&&!m_acc) 
					    || (simd_inst && (reg_pend_v[vrd1] ||reg_pend_v[vrs1] || fetch_wait )); 
			`Itype: 
				halt =!readyI|| reg_pend[rs1] ||reg_pend[rd]|| (load_enable && (fetch_wait))
					 || ( simd_inst && (reg_pend_v[vrs1] || reg_pend_v[vrs2] //||reg_pend_v[vrd1] || reg_pend_v[vrd2]
					 || c1_not_accepting) );			 
			`Stype: 
				halt =!readyI|| reg_pend[rs1] || reg_pend[rs2] 
				 || (!accepting);
			`Btype: halt =!readyI|| reg_pend[rs1] || reg_pend[rs2];
			`Utype: halt=!readyI||reg_pend[rd];
			`Jtype: halt=!readyI||reg_pend[rd];
			default: halt=!readyI;
		endcase

	end
	
	// Registers holding the input data for all custom SIMD instructions
	wire [`VLEN-1:0] c_inA;  assign c_inA = reg_file_v[vrs1];
	wire [`VLEN-1:0] c_inB;  assign c_inB = reg_file_v[vrs2];
	wire [31:0] c_in;        assign c_in  = reg_file  [ rs1];
	
	wire [2:0] c_rd1;  assign c_rd1=vrd1;
	wire [2:0] c_rd2;  assign c_rd2=vrd2; 
	wire [4:0] c_rd;   assign c_rd =rd; 
	
	
	// **** Custom instructions placeholder ****
	wire [`VLEN-1:0] c1_outA; wire [`VLEN-1:0] c1_outB; wire [2:0] c1_out_rd1; wire [2:0] c1_out_rd2; 
	wire c1_out_v; wire c1_out;  wire [4:0] c1_out_rd;    
    wire c1_out_sv; 
    
    Merger2x8x32bit // This can be commented out if not used
             c1_merg (clk, reset, c_rd, c_rd1, c_rd2, c1_en&&!(halt), c_inA, c_inB, 
    		c1_out_v, c1_outA, c1_outB, c1_out_rd, c1_out_rd1, c1_out_rd2,
    		c1_out_sv, c1_out, c1_not_accepting);
 
 
    wire [`VLEN-1:0] c2_outA; wire [`VLEN-1:0] c2_outB; wire [2:0] c2_out_rd1; wire [2:0] c2_out_rd2; 
    wire c2_out_v; 		

    Sorter1x8x32bit // Can be removed or replaced with PrefixSum1x8x32bit etc.
    //PrefixSum1x8x32bit
   	        c2_s (clk, reset,       c_rd1,        c2_en&&!(halt), c_inA,      
    		c2_out_v, c2_outA,                     c2_out_rd1                    );
	
	
	/////// Instantiation of the dummy template ///////
	wire [`VLEN-1:0] c3_outA; wire [`VLEN-1:0] c3_outB; wire [2:0] c3_out_rd1; wire [2:0] c3_out_rd2; 
	wire c3_out_v; wire [31:0] c3_out;  wire [4:0] c3_out_rd; 
	/*
	C3_custom_SIMD_instruction
	              c3 (clk, reset, c3_en&&!(halt), c_rd, c_rd1, c_rd2, c_in, c_inA, c_inB, 
    		c3_out_v, c3_out_rd, c3_out_rd1, c3_out_rd2, c3_out, c3_outA, c3_outB);
  */  		         
	
	// **** Custom instructions placeholder end ****
	
	assign cycles=cycle_counter;
	always @(posedge clk) begin
		if (reset) begin

			for (i=0; i<32; i=i+1) begin
				reg_file[i]<=0;    reg_pend[i]<=0;			
			end	
			for (i=0; i<`NumVregisters; i=i+1) begin
				reg_file_v[i]<=0;  reg_pend_v[i]<=0;		
			end		
			
			reg_file[2] <= StackPointer;
			PC<=StartAddress;
			
			enB<=0;	weB<=0;	
			current_pc <= 0;

			cycle_counter<=0;
			instr_counter<=0;
			
			read_rq_i_in<=0; read_rq_i_out<=0;
			for (i=0; i<4; i=i+1) begin
				read_rq_filter[i]<=0;
				read_rq_reg[i]<=0;
			end
			
		end else begin	
			cycle_counter<=cycle_counter+48'b1;		
			enB<=0;	weB<=0;	
			
			// On a valid result from custom instruction C1, update the registers, and mark them non-pending		
			if(c1_out_v) begin
				reg_file_v[c1_out_rd1]<=c1_outA;
				reg_file_v[c1_out_rd2]<=c1_outB;				 
				reg_pend_v[c1_out_rd1]<=0; reg_pend_v[c1_out_rd2]<=0;	
				
				//if(`DEB) $display("C1_PEND finished %d",cycle_counter+1);		
			end			
			if (c1_out_sv) begin 
				// specific to merge, but a similar approach can be used if results are ready on different times
				reg_file[c1_out_rd]<=c1_out; reg_pend[c1_out_rd]<=0;
			end
			
			// On a valid result from custom instruction C2, update the registers, and mark them non-pending	
			if(c2_out_v) begin				
				reg_file_v[c2_out_rd1]<=c2_outA;
				reg_pend_v[c2_out_rd1]<=0;
				//if(`DEB) $display("C2_PEND finished %d",cycle_counter+1);
			end
			
			// On a valid result from custom instruction C3, update the registers, and mark them non-pending		
			if(c3_out_v) begin
				reg_file[c3_out_rd]<=c1_out;
				reg_pend[c3_out_rd]<=0;
				reg_file_v[c3_out_rd1]<=c1_outA;
				reg_file_v[c3_out_rd2]<=c1_outB;				 
				reg_pend_v[c3_out_rd1]<=0; reg_pend_v[c1_out_rd2]<=0;	
				
				//if(`DEB) $display("C3_PEND finished %d",cycle_counter+1);		
			end	

			// On a valid result from an "M" instruction, store it and mark it non-pending
			if (m_ready) begin
				reg_file[m_rd]<=m_res;
				reg_pend[m_rd]<=0;
				//if (`DEB)$display("MULTI %d -> x%d, cycle: %d, instr %d", m_res, m_rd, cycle_counter, instr_counter);
				//if(`DEB)$display("MULT_PEND finished %d",cycle_counter+1);
			end
			
			// On arriving reads from caches
			if (readyB) begin
				read_rq_i_out<=read_rq_i_out+1;

				//if(`DEB)$display("LOAD_PEND finished %d",cycle_counter+1);
				
				// If it is for a 32-bit register, manipulate it according to the requested format
				if (!rd_read_v) begin
				
					reg_pend[rd_read]<=0;
					
					if (`DEB)$display("x%d released cyc%d %h",rd_read,cycle_counter, dinB);
					case(rd_filter[2:0])
						3'h0: reg_file[rd_read]<= // lb   {{24{dinB[ 7]}},dinB[ 7:0]};
					{{24{dinB[(rd_filter[4:3]+1)*8-1]}},  dinB[(rd_filter[4:3]+1)*8-1-:8]};   
						3'h1: reg_file[rd_read]<= // lh   {{16{dinB[15]}},dinB[15:0]}; 
					{{16{dinB[(rd_filter[4]  +1)*16-1]}}, dinB[(rd_filter[4]  +1)*16-1-:16]}; 
						3'h2: reg_file[rd_read]<=dinB; // lw
						3'h4: reg_file[rd_read]<= // lbu          {24'b0, dinB[ 7:0]};
								                  {24'b0, dinB[(rd_filter[4:3]+1)*8-1-:8]};
						3'h5: reg_file[rd_read]<= // lhu          {16'b0, dinB[15:0]};
								                  {16'b0, dinB[(rd_filter[4]  +1)*16-1-:16]}; 
						default: ;                              
					endcase
					
					
				// If it was from a vector load, then allignement is assumed
				end else begin
					reg_pend_v[rd_read]<=0;
					reg_file_v[rd_read]<=dinB;
					
    			end	
				
			end 
			
			// If there is no stall proceed to update PC and do the rest of the tasks happening in a cycle
			if (!halt) begin
				PC<=PCnext; 	
				instr_counter<=instr_counter+1;
				
				
				// According to the istruction type, bahave differently
				case (iformat)
					`Rtype: begin 
								reg_file[rd]<=alu_dst; 
//if (`DEB)if(alui_enable)$display("%d(%d_%d)->x%d, cycle: %d, instr %d ",alu_dst,alu_rs1,alu_rs2, rd, cycle_counter, instr_counter);
								reg_pend[rd]<=0;
								
								if (simd_inst && (func3==2)) begin 
									//if (`DEB)$display("SIMDwrite %h from v%d daddr %h cyc%d PC%h", reg_file_v[vrs1],vrs1, daddr,cycle_counter,PC);
									doutB <= reg_file_v[vrs1];
									weB<={(`VLEN/8){1'b1}};
									current_pc <= PC;
									addrB <= {daddr[`DADDR_bits-1:`VLEN_Log2-3],{(`VLEN_Log2-3){1'b0}} };
								end
								
							end				
								
					`Itype: begin 
								if (alui_enable) begin	
									reg_file[rd] <= alu_dst; 
									//if (`DEB)$display("%h->x%d from %h %h PC %h",alu_dst, rd,alu_rs1, alu_rs2,PC);
								end 
								if (absolute_pc) begin
									reg_file[rd] <= pc4;
								end	
								if (counters) begin 
									//if (`DEB)$display("Counter %h %h -> x%d imm %b",instr_counter, cycle_counter , rd, {immediate[7],immediate[1:0]});
									
									case({immediate[7],immediate[1:0]}) 
										3'b000: reg_file[rd] <=cycle_counter [31: 0];    // rdcycle
										3'b001: reg_file[rd] <=cycle_counter [31: 0]<<3; // rdtime  (8 ns per cycle for 125 MHz)
										3'b010: reg_file[rd] <=instr_counter [31: 0];    // rdinstret
										3'b100: reg_file[rd] <=cycle_counter [47:32];    // rdcycleh
										3'b101: reg_file[rd] <=cycle_counter [47:32+3];  // rdtimeh (8 ns per cycle for 125 MHz)
										3'b110: reg_file[rd] <=instr_counter [47:32];    //rdinstreth
									endcase									
								end							
								reg_pend[rd]<=0;
								
								if (simd_inst) begin 
									reg_pend[rd]<=1; 
									reg_pend_v[vrd1]<=1; 
									reg_pend_v[vrd2]<=1;																
								end	
								
							end
					`Stype: begin 
							
							// For stores, update the write bits for the DL1 (weB) and data (doutB), according to the command			
							doutB <= reg_file[rs2]; 				
							case(func3)
								3'h0: begin // sb
									weB<=(1'b1)<<daddr[1:0];
									current_pc <= PC;
									doutB <= reg_file[rs2]<<(8*daddr[1:0]);
									
									 end 
								3'h1: begin // sh
									weB<=(2'b11)<<(2*daddr[1]); 
									current_pc <= PC;
									doutB <= reg_file[rs2]<<(16*daddr[1]);
									if (`DEB)if (daddr[0]!=0)$display("ERROR");

									end 
								3'h2: begin 
									weB<=4'b1111; // sw
									current_pc <= PC;
									if (`DEB)if (daddr[1:0]!=0)$display("ERROR");
									end
								default: weB<=0;                              
							endcase 			
							
							addrB <= {daddr[`DADDR_bits-1:2],2'b0};
							
							// Just a simple way to read stdout (at address 0x07000000) in simulation
							//if (`STDO) if (daddr[28-1-:4]==7)
							//	 $write("%s",reg_file[rs2][7:0]);

						end
					`Btype: ;
					`Utype: begin 
								reg_file[rd]<=(auipc_enable)?auipc:immediate; 
								reg_pend[rd]<=0;
						end
					`Jtype: begin 
								reg_file[rd]<=pc4; 
								reg_pend[rd]<=0;
						end
					default: ;
				endcase	
				
				// On loads, make the request to the caches, and keep the rd (or vrd for SIMD)
				if (load_enable) begin
					enB<=1;
					current_pc <= PC;										
					read_rq_i_in<=read_rq_i_in+1;
					if (simd_inst) begin
						reg_pend_v[vrd1]<=1;						
						//if (`DEB)$display("v%d pending",vrd1);
						read_rq_reg[read_rq_i_in]<=6'b100000 |vrd1;
					end else begin
						reg_pend[rd]<=1;						
						//if (`DEB)$display("x%d pending",rd);
						read_rq_reg[read_rq_i_in]<=rd;
					end

					read_rq_filter[read_rq_i_in]<={daddr[1:0],func3};
					addrB <= {daddr[`DADDR_bits-1:2],2'b0};
				end
							
				if (m_inst) begin
					reg_pend[rd]<=1;
				end 
				
				// (Only useful for the timeline plot)
				
				
			end	else begin
				
			end		
			
			// Registers x0 and v0 represent 0. They are removed by the implementation tools automatically.
			reg_file  [0]<=0;		reg_pend  [0]<=0;	
			reg_file_v[0]<=0;		reg_pend_v[0]<=0;
		end	
		
	end
	
	initial begin
		if (`DEB)$dumpvars(0, clk, reset, PC, PCnext, instr, enB, weB, accepting, halt,read_rq_i_out, read_rq_i_in,iformat, cycle_counter, rs1,rs2,rd,next_direction,next_step, vrs1, vrs2, vrd1, vrd2, func3, immediate,instr_counter);
	end
endmodule // Core


