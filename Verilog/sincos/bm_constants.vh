// Include file for Box-Muller Gaussian Random Noise Generator

`ifndef _bm_constants_vh_
`define _bm_constants_vh_

`define MAX_FIXEDPT_VAL                  56'sd20266198323167232  //  72
`define MIN_FIXEDPT_VAL                  -56'sd20266198323167232 // -72
`define FIXEDPT_OP_BITWIDTH              56   // S7.48
`define FIXEDPT_PROD_BITWIDTH            112
`define FIXEDPT_PROD_SHIFTVAL            47
`define OPTYPE_SIN                       1'd0
`define OPTYPE_COS                       1'd1
`define OPTYPE_LOG                       1'd0
`define OPTYPE_SQRT                      1'd1

`endif  // _bm_constants_vh_


