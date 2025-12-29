// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vtop_level__Syms.h"


void Vtop_level___024root__trace_chg_0_sub_0(Vtop_level___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vtop_level___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root__trace_chg_0\n"); );
    // Init
    Vtop_level___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop_level___024root*>(voidSelf);
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vtop_level___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vtop_level___024root__trace_chg_0_sub_0(Vtop_level___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[1U])) {
        bufp->chgCData(oldp+0,(vlSelf->top_level__DOT__spi_inst__DOT__rx_reg),8);
        bufp->chgBit(oldp+1,((0U != vlSelf->top_level__DOT__spi_inst__DOT__state)));
        bufp->chgSData(oldp+2,(vlSelf->top_level__DOT__pm_inst__DOT__audio_buffer),16);
        bufp->chgIData(oldp+3,(vlSelf->top_level__DOT__cg_inst__DOT__x_reg),32);
        bufp->chgIData(oldp+4,(vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__one_minus_x),32);
        bufp->chgQData(oldp+5,(vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product1),64);
        bufp->chgIData(oldp+7,(vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__r_times_x),32);
        bufp->chgQData(oldp+8,(vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product2),64);
        bufp->chgIData(oldp+10,(vlSelf->top_level__DOT__pm_inst__DOT__state),32);
        bufp->chgIData(oldp+11,(vlSelf->top_level__DOT__spi_inst__DOT__state),32);
        bufp->chgCData(oldp+12,(vlSelf->top_level__DOT__spi_inst__DOT__tx_reg),8);
        bufp->chgCData(oldp+13,(vlSelf->top_level__DOT__spi_inst__DOT__clk_counter),3);
        bufp->chgCData(oldp+14,(vlSelf->top_level__DOT__spi_inst__DOT__bit_counter),4);
    }
    bufp->chgBit(oldp+15,(vlSelf->clk));
    bufp->chgBit(oldp+16,(vlSelf->rst));
    bufp->chgBit(oldp+17,(vlSelf->push_to_talk));
    bufp->chgSData(oldp+18,(vlSelf->adc_data_in),16);
    bufp->chgBit(oldp+19,(vlSelf->adc_data_valid));
    bufp->chgSData(oldp+20,(vlSelf->dac_data_out),16);
    bufp->chgBit(oldp+21,(vlSelf->dac_data_valid));
    bufp->chgBit(oldp+22,(vlSelf->spi_sclk));
    bufp->chgBit(oldp+23,(vlSelf->spi_mosi));
    bufp->chgBit(oldp+24,(vlSelf->spi_miso));
    bufp->chgBit(oldp+25,(vlSelf->spi_cs));
    bufp->chgSData(oldp+26,(vlSelf->radio_rx_data),16);
    bufp->chgBit(oldp+27,(vlSelf->radio_rx_valid));
    bufp->chgSData(oldp+28,(vlSelf->encrypted_data_out),16);
    bufp->chgSData(oldp+29,(vlSelf->top_level__DOT__decrypted_data_result),16);
    bufp->chgIData(oldp+30,(vlSelf->top_level__DOT__pm_inst__DOT__next_state),32);
}

void Vtop_level___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root__trace_cleanup\n"); );
    // Init
    Vtop_level___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop_level___024root*>(voidSelf);
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
}
