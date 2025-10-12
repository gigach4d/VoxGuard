// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop_level.h for the primary calling header

#ifndef VERILATED_VTOP_LEVEL___024ROOT_H_
#define VERILATED_VTOP_LEVEL___024ROOT_H_  // guard

#include "verilated.h"


class Vtop_level__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop_level___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(push_to_talk,0,0);
    VL_IN8(adc_data_valid,0,0);
    VL_OUT8(dac_data_valid,0,0);
    VL_OUT8(spi_sclk,0,0);
    VL_OUT8(spi_mosi,0,0);
    VL_IN8(spi_miso,0,0);
    VL_OUT8(spi_cs,0,0);
    VL_IN8(radio_rx_valid,0,0);
    CData/*7:0*/ top_level__DOT__spi_inst__DOT__tx_reg;
    CData/*7:0*/ top_level__DOT__spi_inst__DOT__rx_reg;
    CData/*2:0*/ top_level__DOT__spi_inst__DOT__clk_counter;
    CData/*3:0*/ top_level__DOT__spi_inst__DOT__bit_counter;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VicoFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __VactContinue;
    VL_IN16(adc_data_in,15,0);
    VL_OUT16(dac_data_out,15,0);
    VL_IN16(radio_rx_data,15,0);
    VL_OUT16(encrypted_data_out,15,0);
    SData/*15:0*/ top_level__DOT__decrypted_data_result;
    SData/*15:0*/ top_level__DOT__pm_inst__DOT__audio_buffer;
    IData/*31:0*/ top_level__DOT__pm_inst__DOT__state;
    IData/*31:0*/ top_level__DOT__pm_inst__DOT__next_state;
    IData/*31:0*/ top_level__DOT__spi_inst__DOT__state;
    IData/*31:0*/ top_level__DOT__cg_inst__DOT__x_reg;
    IData/*31:0*/ top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__one_minus_x;
    IData/*31:0*/ top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__r_times_x;
    IData/*31:0*/ __VactIterCount;
    QData/*63:0*/ top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product1;
    QData/*63:0*/ top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product2;
    VlUnpacked<CData/*0:0*/, 2> __Vm_traceActivity;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop_level__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtop_level___024root(Vtop_level__Syms* symsp, const char* v__name);
    ~Vtop_level___024root();
    VL_UNCOPYABLE(Vtop_level___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
