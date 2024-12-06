# -- *******************************************************************************/
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
#set_global_assignment -name ENABLE_INIT_DONE_OUTPUT ON

# ------------------clk---------------------#
set_location_assignment PIN_91   -to fin
# ------------------reset 4---------------------#
#set_location_assignment PIN_90   -to Reset

# ------------------led 0-> 7---------------------#
set_location_assignment PIN_39 -to debug[0]
set_location_assignment PIN_31 -to debug[1]
set_location_assignment PIN_3 -to debug[2]
set_location_assignment PIN_2 -to debug[3]
set_location_assignment PIN_1 -to debug[4]
set_location_assignment PIN_144 -to debug[5]
set_location_assignment PIN_143 -to debug[6]
set_location_assignment PIN_142 -to debug[7]
# ------------------7 SEG a-->h ---------------------#

set_location_assignment PIN_100 -to segout[0]
set_location_assignment PIN_111 -to segout[1]
set_location_assignment PIN_104 -to segout[2]
set_location_assignment PIN_110 -to segout[3]
set_location_assignment PIN_106 -to segout[4]
set_location_assignment PIN_101 -to segout[5]
set_location_assignment PIN_103 -to segout[6]
set_location_assignment PIN_105 -to segout[7]

set_location_assignment PIN_87 -to segsel[3]
set_location_assignment PIN_86 -to segsel[2]
set_location_assignment PIN_99 -to segsel[1]
set_location_assignment PIN_98 -to segsel[0]


# ------------------«öÁä key 0->3 ------------------#
#set_location_assignment PIN_11 -to sw
#set_location_assignment PIN_25 -to key_data[1]
#set_location_assignment PIN_24 -to key_data[2]
set_location_assignment PIN_23 -to nReset


# ----------------- ¼·½X¶}Ãö -----------------------#
set_location_assignment PIN_89 -to dipsw1[3]
set_location_assignment PIN_88 -to dipsw1[2]
set_location_assignment PIN_33 -to dipsw1[1]
set_location_assignment PIN_34 -to dipsw1[0]

# ----------------- Keypad --------------------#
set_location_assignment PIN_85 -to key_col[0]
set_location_assignment PIN_83 -to key_col[1]
set_location_assignment PIN_77 -to key_col[2]
set_location_assignment PIN_75 -to key_col[3]
set_location_assignment PIN_73 -to key_scan[0]  
set_location_assignment PIN_71 -to key_scan[1]
set_location_assignment PIN_69 -to key_scan[2]
# # error
# # set_location_assignment PIN_67 -to RowIn[3]  
set_location_assignment PIN_65 -to key_scan[3]

#set_location_assignment PIN_58 -to key_col[0]
#set_location_assignment PIN_54 -to key_col[1]
#set_location_assignment PIN_52 -to key_col[2]
#set_location_assignment PIN_50 -to key_col[3]
#set_location_assignment PIN_46 -to key_scan[0]  
#set_location_assignment PIN_43 -to key_scan[1]
# #set_location_assignment PIN_39 -to key_scan[2]
# #set_location_assignment PIN_34 -to key_scan[3]



# ----------------RGB TFT 128x160 LCD ---------------------#
set_location_assignment PIN_84 -to SCL
set_location_assignment PIN_80 -to SDA
set_location_assignment PIN_76 -to RES
set_location_assignment PIN_74 -to DC
set_location_assignment PIN_72 -to CS
set_location_assignment PIN_70 -to BL
# ----------------Other ---------------------------#
set_location_assignment PIN_68 -to DHT11_PIN

set_location_assignment PIN_66 -to TSL2561_scl
set_location_assignment PIN_64 -to TSL2561_sda

set_location_assignment PIN_59 -to SD178_sda

set_location_assignment PIN_55 -to SD178_scl
set_location_assignment PIN_53 -to SD178_nrst
