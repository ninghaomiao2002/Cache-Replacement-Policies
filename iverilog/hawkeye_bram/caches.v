// In powers of 2 above 1
`define IL1sets 64

`define DL1sets 32
`define DL1ways 8

`define DL2sets 32
`define DL2ways 8
`define DL2block 16384 
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



// Implementation of the IL1 cache in registers

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
    reg [`OCC_WIDTH-1:0] occupancy_vector [`DL1sets-1:0][`VECTOR_SIZE-1:0];
    integer s, q, q_idx;

    always @(posedge clk) begin
        if (reset) begin
            for (s = 0; s < `DL1sets; s = s + 1)
                for (q = 0; q < `VECTOR_SIZE; q = q + 1)
                    occupancy_vector[s][q] = 0;
            should_cache = 1;
        end 
		if (access) begin
			// $display("last timestep ", last_timestep, " curr_timestep ", curr_timestep, " pc ", pc, " is_reuse ", is_reuse);
			if (is_reuse) begin
				should_cache = 1;
				occupancy_vector[set][curr_timestep] = 0;
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
    reg [`OCC_WIDTH-1:0] occupancy_vector [`DL2sets-1:0][`VECTOR_SIZE-1:0];
    integer s, q, q_idx;

    always @(posedge clk) begin
        if (reset) begin
            for (s = 0; s < `DL2sets; s = s + 1)
                for (q = 0; q < `VECTOR_SIZE; q = q + 1)
                    occupancy_vector[s][q] = 0;
            should_cache = 1;

        end 
		if (access) begin
			// $display("last timestep ", last_timestep, " curr_timestep ", curr_timestep, " pc ", pc, " is_reuse ", is_reuse);
			if (is_reuse) begin
				should_cache = 1;
				occupancy_vector[set][curr_timestep] = 0;
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

	reg [2:0] max_rrpv;
	reg [`DADDR_bits-(`VLEN_Log2-3)-`DL1setsLog2-1:0] tag_history [`DL1sets-1:0][`VECTOR_SIZE-1:0];
	reg [4:0] timestep_history [`DL1sets-1:0][`VECTOR_SIZE-1:0];

	reg found_tag_match;
	reg [4:0] last_timestep_for_tag;


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
						if (tag_history[set][j_]==tag && !found_tag_match) begin
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
					// $display("tag: ", tag);
					
				end

                if (hit) begin
                    hit_count<=hit_count+1;
                    $display("L1 hit_count %d, access_count %d",hit_count, access_count);

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
    reg [4:0] curr_timestep; 
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

	reg [2:0] max_rrpv;
	reg [`DADDR_bits-(`VLEN_Log2-3)-`DL2setsLog2-1:0] tag_history [`DL2sets-1:0][`VECTOR_SIZE-1:0];
	reg [4:0] timestep_history [`DL2sets-1:0][`VECTOR_SIZE-1:0];

	reg found_tag_match;
	reg [4:0] last_timestep_for_tag;


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
				end else begin
					train_down <= 1;
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
					
				end

				if (hit) begin
					hit_count<=hit_count+1;
					// hit_rate<=(hit_count*100)/access_count;
					$display("L2 hit_count %d, access_count %d",hit_count, access_count);
                    
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
