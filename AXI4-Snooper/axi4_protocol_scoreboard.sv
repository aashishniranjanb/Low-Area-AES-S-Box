import uvm_pkg::*;
`include "uvm_macros.svh"

class axi4_protocol_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi4_protocol_scoreboard)

    // Virtual interface to read the error flags directly from the snooper
    virtual axi4_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi4_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found in scoreboard!")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            
            // Route the snooper's hardware flags directly into the UVM logger
            if (vif.err_aw_handshake)
                `uvm_error("AXI4_SNOOPER", "PROTOCOL VIOLATION: AW Handshake Dropped!")
            
            if (vif.err_w_handshake)
                `uvm_error("AXI4_SNOOPER", "PROTOCOL VIOLATION: W Handshake Dropped!")
                
            if (vif.err_4kb_boundary)
                `uvm_error("AXI4_SNOOPER", "PROTOCOL VIOLATION: 4KB Boundary Crossed!")
                
            if (vif.err_wlast_mismatch)
                `uvm_error("AXI4_SNOOPER", "PROTOCOL VIOLATION: WLAST Timing Mismatch!")
        end
    endtask
endclass
