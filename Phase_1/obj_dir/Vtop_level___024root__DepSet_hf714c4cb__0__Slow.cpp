// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop_level.h for the primary calling header

#include "Vtop_level__pch.h"
#include "Vtop_level___024root.h"

VL_ATTR_COLD void Vtop_level___024root___eval_static(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vtop_level___024root___eval_initial__TOP(Vtop_level___024root* vlSelf);

VL_ATTR_COLD void Vtop_level___024root___eval_initial(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_initial\n"); );
    // Body
    Vtop_level___024root___eval_initial__TOP(vlSelf);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
}

VL_ATTR_COLD void Vtop_level___024root___eval_initial__TOP(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_initial__TOP\n"); );
    // Body
    vlSelf->spi_cs = 1U;
}

VL_ATTR_COLD void Vtop_level___024root___eval_final(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__stl(Vtop_level___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtop_level___024root___eval_phase__stl(Vtop_level___024root* vlSelf);

VL_ATTR_COLD void Vtop_level___024root___eval_settle(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vtop_level___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("src/top_level.sv", 5, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vtop_level___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__stl(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtop_level___024root___stl_sequent__TOP__0(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___stl_sequent__TOP__0\n"); );
    // Body
    vlSelf->dac_data_valid = 0U;
    vlSelf->spi_mosi = (1U & ((IData)(vlSelf->top_level__DOT__spi_inst__DOT__tx_reg) 
                              >> 7U));
    vlSelf->encrypted_data_out = (0xffffU & ((IData)(vlSelf->top_level__DOT__pm_inst__DOT__audio_buffer) 
                                             ^ (vlSelf->top_level__DOT__cg_inst__DOT__x_reg 
                                                >> 0x10U)));
    vlSelf->top_level__DOT__decrypted_data_result = 
        (0xffffU & ((IData)(vlSelf->radio_rx_data) 
                    ^ (vlSelf->top_level__DOT__cg_inst__DOT__x_reg 
                       >> 0x10U)));
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

VL_ATTR_COLD void Vtop_level___024root___eval_stl(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vtop_level___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vtop_level___024root___eval_triggers__stl(Vtop_level___024root* vlSelf);

VL_ATTR_COLD bool Vtop_level___024root___eval_phase__stl(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtop_level___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vtop_level___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__ico(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VicoTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__act(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop_level___024root___dump_triggers__nba(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtop_level___024root___ctor_var_reset(Vtop_level___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop_level__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop_level___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst = VL_RAND_RESET_I(1);
    vlSelf->push_to_talk = VL_RAND_RESET_I(1);
    vlSelf->adc_data_in = VL_RAND_RESET_I(16);
    vlSelf->adc_data_valid = VL_RAND_RESET_I(1);
    vlSelf->dac_data_out = VL_RAND_RESET_I(16);
    vlSelf->dac_data_valid = VL_RAND_RESET_I(1);
    vlSelf->spi_sclk = VL_RAND_RESET_I(1);
    vlSelf->spi_mosi = VL_RAND_RESET_I(1);
    vlSelf->spi_miso = VL_RAND_RESET_I(1);
    vlSelf->spi_cs = VL_RAND_RESET_I(1);
    vlSelf->radio_rx_data = VL_RAND_RESET_I(16);
    vlSelf->radio_rx_valid = VL_RAND_RESET_I(1);
    vlSelf->encrypted_data_out = VL_RAND_RESET_I(16);
    vlSelf->top_level__DOT__decrypted_data_result = VL_RAND_RESET_I(16);
    vlSelf->top_level__DOT__pm_inst__DOT__state = 0;
    vlSelf->top_level__DOT__pm_inst__DOT__audio_buffer = VL_RAND_RESET_I(16);
    vlSelf->top_level__DOT__pm_inst__DOT__next_state = 0;
    vlSelf->top_level__DOT__spi_inst__DOT__state = 0;
    vlSelf->top_level__DOT__spi_inst__DOT__tx_reg = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__spi_inst__DOT__rx_reg = VL_RAND_RESET_I(8);
    vlSelf->top_level__DOT__spi_inst__DOT__clk_counter = VL_RAND_RESET_I(3);
    vlSelf->top_level__DOT__spi_inst__DOT__bit_counter = VL_RAND_RESET_I(4);
    vlSelf->top_level__DOT__cg_inst__DOT__x_reg = VL_RAND_RESET_I(32);
    vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__one_minus_x = VL_RAND_RESET_I(32);
    vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product1 = VL_RAND_RESET_Q(64);
    vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__r_times_x = VL_RAND_RESET_I(32);
    vlSelf->top_level__DOT__cg_inst__DOT__unnamedblk1__DOT__product2 = VL_RAND_RESET_Q(64);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = 0;
    }
}
