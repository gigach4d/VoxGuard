// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop_level.h for the primary calling header

#include "Vtop_level__pch.h"
#include "Vtop_level___024root.h"

VL_INLINE_OPT void Vtop_level___024root___ico_sequent__TOP__0(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___ico_sequent__TOP__0\n"); );
    // Body
    vlSelf->top_level__DOT__decrypted_data_result = 
        (0xffffU & ((IData)(vlSelf->radio_rx_data) 
                    ^ (vlSelf->top_level__DOT__cg_inst__DOT__x_reg 
                       >> 0x10U)));
    vlSelf->dac_data_out = 0U;
    if ((0U != vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        if ((1U != vlSelf->top_level__DOT__pm_inst__DOT__state)) {
            if ((2U != vlSelf->top_level__DOT__pm_inst__DOT__state)) {
                if ((3U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
                    vlSelf->dac_data_out = vlSelf->top_level__DOT__decrypted_data_result;
                }
            }
        }
    }
    vlSelf->top_level__DOT__pm_inst__DOT__next_state 
        = vlSelf->top_level__DOT__pm_inst__DOT__state;
    if ((0U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        if (vlSelf->push_to_talk) {
            if (vlSelf->adc_data_valid) {
                vlSelf->top_level__DOT__pm_inst__DOT__next_state = 1U;
            }
        } else {
            vlSelf->top_level__DOT__pm_inst__DOT__next_state = 2U;
        }
    } else if ((1U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        vlSelf->top_level__DOT__pm_inst__DOT__next_state = 0U;
    } else if ((2U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        if (vlSelf->push_to_talk) {
            vlSelf->top_level__DOT__pm_inst__DOT__next_state = 0U;
        } else if ((0U != (IData)(vlSelf->top_level__DOT__decrypted_data_result))) {
            vlSelf->top_level__DOT__pm_inst__DOT__next_state = 3U;
        }
    } else {
        vlSelf->top_level__DOT__pm_inst__DOT__next_state = 0U;
    }
}

void Vtop_level___024root___eval_ico(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_ico\n"); );
    // Body
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        Vtop_level___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void Vtop_level___024root___eval_triggers__ico(Vtop_level___024root* vlSelf);

bool Vtop_level___024root___eval_phase__ico(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__ico\n"); );
    // Init
    CData/*0:0*/ __VicoExecute;
    // Body
    Vtop_level___024root___eval_triggers__ico(vlSelf);
    __VicoExecute = vlSelf->__VicoTriggered.any();
    if (__VicoExecute) {
        Vtop_level___024root___eval_ico(vlSelf);
    }
    return (__VicoExecute);
}

void Vtop_level___024root___eval_act(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vtop_level___024root___nba_sequent__TOP__0(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___nba_sequent__TOP__0\n"); );
    // Init
    IData/*31:0*/ __Vdly__top_level__DOT__spi_inst__DOT__state;
    __Vdly__top_level__DOT__spi_inst__DOT__state = 0;
    CData/*0:0*/ __Vdly__spi_sclk;
    __Vdly__spi_sclk = 0;
    CData/*2:0*/ __Vdly__top_level__DOT__spi_inst__DOT__clk_counter;
    __Vdly__top_level__DOT__spi_inst__DOT__clk_counter = 0;
    CData/*3:0*/ __Vdly__top_level__DOT__spi_inst__DOT__bit_counter;
    __Vdly__top_level__DOT__spi_inst__DOT__bit_counter = 0;
    CData/*7:0*/ __Vdly__top_level__DOT__spi_inst__DOT__tx_reg;
    __Vdly__top_level__DOT__spi_inst__DOT__tx_reg = 0;
    CData/*7:0*/ __Vdly__top_level__DOT__spi_inst__DOT__rx_reg;
    __Vdly__top_level__DOT__spi_inst__DOT__rx_reg = 0;
    IData/*31:0*/ __Vdly__top_level__DOT__cg_inst__DOT__x_reg;
    __Vdly__top_level__DOT__cg_inst__DOT__x_reg = 0;
    // Body
    __Vdly__top_level__DOT__spi_inst__DOT__rx_reg = vlSelf->top_level__DOT__spi_inst__DOT__rx_reg;
    __Vdly__top_level__DOT__spi_inst__DOT__bit_counter 
        = vlSelf->top_level__DOT__spi_inst__DOT__bit_counter;
    __Vdly__top_level__DOT__spi_inst__DOT__clk_counter 
        = vlSelf->top_level__DOT__spi_inst__DOT__clk_counter;
    __Vdly__spi_sclk = vlSelf->spi_sclk;
    __Vdly__top_level__DOT__spi_inst__DOT__state = vlSelf->top_level__DOT__spi_inst__DOT__state;
    __Vdly__top_level__DOT__spi_inst__DOT__tx_reg = vlSelf->top_level__DOT__spi_inst__DOT__tx_reg;
    __Vdly__top_level__DOT__cg_inst__DOT__x_reg = vlSelf->top_level__DOT__cg_inst__DOT__x_reg;
    if (vlSelf->rst) {
        __Vdly__top_level__DOT__spi_inst__DOT__state = 0U;
        __Vdly__spi_sclk = 1U;
        __Vdly__top_level__DOT__spi_inst__DOT__clk_counter = 0U;
        __Vdly__top_level__DOT__spi_inst__DOT__bit_counter = 0U;
        __Vdly__top_level__DOT__spi_inst__DOT__tx_reg = 0U;
        __Vdly__top_level__DOT__spi_inst__DOT__rx_reg = 0U;
        __Vdly__top_level__DOT__cg_inst__DOT__x_reg = 0xf9add3fU;
        vlSelf->top_level__DOT__pm_inst__DOT__audio_buffer = 0U;
        vlSelf->top_level__DOT__pm_inst__DOT__state = 0U;
    } else {
        if ((0U == vlSelf->top_level__DOT__spi_inst__DOT__state)) {
            __Vdly__spi_sclk = 1U;
        } else if ((1U == vlSelf->top_level__DOT__spi_inst__DOT__state)) {
            if ((3U == (IData)(vlSelf->top_level__DOT__spi_inst__DOT__clk_counter))) {
                __Vdly__spi_sclk = (1U & (~ (IData)(vlSelf->spi_sclk)));
                __Vdly__top_level__DOT__spi_inst__DOT__clk_counter = 0U;
                if (vlSelf->spi_sclk) {
                    if ((8U > (IData)(vlSelf->top_level__DOT__spi_inst__DOT__bit_counter))) {
                        __Vdly__top_level__DOT__spi_inst__DOT__tx_reg 
                            = (0xffU & VL_SHIFTL_III(8,8,32, (IData)(vlSelf->top_level__DOT__spi_inst__DOT__tx_reg), 1U));
                        __Vdly__top_level__DOT__spi_inst__DOT__rx_reg 
                            = ((0xfeU & ((IData)(vlSelf->top_level__DOT__spi_inst__DOT__rx_reg) 
                                         << 1U)) | (IData)(vlSelf->spi_miso));
                        __Vdly__top_level__DOT__spi_inst__DOT__bit_counter 
                            = (0xfU & ((IData)(1U) 
                                       + (IData)(vlSelf->top_level__DOT__spi_inst__DOT__bit_counter)));
                    } else {
                        __Vdly__top_level__DOT__spi_inst__DOT__state = 2U;
                    }
                }
            } else {
                __Vdly__top_level__DOT__spi_inst__DOT__clk_counter 
                    = (7U & ((IData)(1U) + (IData)(vlSelf->top_level__DOT__spi_inst__DOT__clk_counter)));
            }
        } else if ((2U == vlSelf->top_level__DOT__spi_inst__DOT__state)) {
            __Vdly__top_level__DOT__spi_inst__DOT__state = 0U;
        }
        if (vlSelf->adc_data_valid) {
            vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__one_minus_x 
                = ((IData)(0x40000000U) - vlSelf->top_level__DOT__cg_inst__DOT__x_reg);
            vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product1 
                = VL_SHIFTL_QQI(64,64,32, (QData)((IData)(vlSelf->top_level__DOT__cg_inst__DOT__x_reg)), 0x1eU);
            vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__r_times_x 
                = (IData)((vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product1 
                           >> 0x1eU));
            vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product2 
                = ((QData)((IData)(vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__r_times_x)) 
                   * (QData)((IData)(vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__one_minus_x)));
            __Vdly__top_level__DOT__cg_inst__DOT__x_reg 
                = (IData)((vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product2 
                           >> 0x20U));
        }
        if ((1U == vlSelf->top_level__DOT__pm_inst__DOT__next_state)) {
            vlSelf->top_level__DOT__pm_inst__DOT__audio_buffer 
                = vlSelf->adc_data_in;
        }
        vlSelf->top_level__DOT__pm_inst__DOT__state 
            = vlSelf->top_level__DOT__pm_inst__DOT__next_state;
    }
    vlSelf->top_level__DOT__spi_inst__DOT__state = __Vdly__top_level__DOT__spi_inst__DOT__state;
    vlSelf->spi_sclk = __Vdly__spi_sclk;
    vlSelf->top_level__DOT__spi_inst__DOT__clk_counter 
        = __Vdly__top_level__DOT__spi_inst__DOT__clk_counter;
    vlSelf->top_level__DOT__spi_inst__DOT__bit_counter 
        = __Vdly__top_level__DOT__spi_inst__DOT__bit_counter;
    vlSelf->top_level__DOT__spi_inst__DOT__rx_reg = __Vdly__top_level__DOT__spi_inst__DOT__rx_reg;
    vlSelf->top_level__DOT__spi_inst__DOT__tx_reg = __Vdly__top_level__DOT__spi_inst__DOT__tx_reg;
    vlSelf->top_level__DOT__cg_inst__DOT__x_reg = __Vdly__top_level__DOT__cg_inst__DOT__x_reg;
    vlSelf->spi_mosi = (1U & ((IData)(vlSelf->top_level__DOT__spi_inst__DOT__tx_reg) 
                              >> 7U));
    vlSelf->top_level__DOT__decrypted_data_result = 
        (0xffffU & ((IData)(vlSelf->radio_rx_data) 
                    ^ (vlSelf->top_level__DOT__cg_inst__DOT__x_reg 
                       >> 0x10U)));
    vlSelf->encrypted_data_out = (0xffffU & ((IData)(vlSelf->top_level__DOT__pm_inst__DOT__audio_buffer) 
                                             ^ (vlSelf->top_level__DOT__cg_inst__DOT__x_reg 
                                                >> 0x10U)));
    vlSelf->dac_data_valid = 0U;
    vlSelf->dac_data_out = 0U;
    if ((0U != vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        if ((1U != vlSelf->top_level__DOT__pm_inst__DOT__state)) {
            if ((2U != vlSelf->top_level__DOT__pm_inst__DOT__state)) {
                if ((3U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
                    vlSelf->dac_data_valid = 1U;
                    vlSelf->dac_data_out = vlSelf->top_level__DOT__decrypted_data_result;
                }
            }
        }
    }
    vlSelf->top_level__DOT__pm_inst__DOT__next_state 
        = vlSelf->top_level__DOT__pm_inst__DOT__state;
    if ((0U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        if (vlSelf->push_to_talk) {
            if (vlSelf->adc_data_valid) {
                vlSelf->top_level__DOT__pm_inst__DOT__next_state = 1U;
            }
        } else {
            vlSelf->top_level__DOT__pm_inst__DOT__next_state = 2U;
        }
    } else if ((1U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        vlSelf->top_level__DOT__pm_inst__DOT__next_state = 0U;
    } else if ((2U == vlSelf->top_level__DOT__pm_inst__DOT__state)) {
        if (vlSelf->push_to_talk) {
            vlSelf->top_level__DOT__pm_inst__DOT__next_state = 0U;
        } else if ((0U != (IData)(vlSelf->top_level__DOT__decrypted_data_result))) {
            vlSelf->top_level__DOT__pm_inst__DOT__next_state = 3U;
        }
    } else {
        vlSelf->top_level__DOT__pm_inst__DOT__next_state = 0U;
    }
}

void Vtop_level___024root___eval_nba(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vtop_level___024root___nba_sequent__TOP__0(vlSelf);
        vlSelf->__Vm_traceActivity[1U] = 1U;
    }
}

void Vtop_level___024root___eval_triggers__act(Vtop_level___024root* vlSelf);

bool Vtop_level___024root___eval_phase__act(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtop_level___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vtop_level___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtop_level___024root___eval_phase__nba(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtop_level___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__ico(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__nba(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__act(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG

void Vtop_level___024root___eval(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VicoIterCount;
    CData/*0:0*/ __VicoContinue;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VicoIterCount = 0U;
    vlSelf->__VicoFirstIteration = 1U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        if (VL_UNLIKELY((0x64U < __VicoIterCount))) {
#ifdef VL_DEBUG
            Vtop_level___024root___dump_triggers__ico(vlSelf);
#endif
            VL_FATAL_MT("src/top_level.sv", 5, "", "Input combinational region did not converge.");
        }
        __VicoIterCount = ((IData)(1U) + __VicoIterCount);
        __VicoContinue = 0U;
        if (Vtop_level___024root___eval_phase__ico(vlSelf)) {
            __VicoContinue = 1U;
        }
        vlSelf->__VicoFirstIteration = 0U;
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vtop_level___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("src/top_level.sv", 5, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vtop_level___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("src/top_level.sv", 5, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vtop_level___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vtop_level___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtop_level___024root___eval_debug_assertions(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst & 0xfeU))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY((vlSelf->push_to_talk & 0xfeU))) {
        Verilated::overWidthError("push_to_talk");}
    if (VL_UNLIKELY((vlSelf->adc_data_valid & 0xfeU))) {
        Verilated::overWidthError("adc_data_valid");}
    if (VL_UNLIKELY((vlSelf->spi_miso & 0xfeU))) {
        Verilated::overWidthError("spi_miso");}
    if (VL_UNLIKELY((vlSelf->radio_rx_valid & 0xfeU))) {
        Verilated::overWidthError("radio_rx_valid");}
}
#endif  // VL_DEBUG
