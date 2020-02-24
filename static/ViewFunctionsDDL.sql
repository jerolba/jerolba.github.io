DROP TABLE IF EXISTS table_x CASCADE;
CREATE TABLE table_x (id serial NOT NULL, org_id varchar NULL
, x_0 int4 NOT NULL
, x_1 int4 NOT NULL
, x_2 int4 NOT NULL
, x_3 int4 NOT NULL
, x_4 int4 NOT NULL
, x_5 int4 NOT NULL
, x_6 int4 NOT NULL
, x_7 int4 NOT NULL
, x_8 int4 NOT NULL
, x_9 int4 NOT NULL
, CONSTRAINT table_x_pkey PRIMARY KEY (id));
CREATE INDEX table_x_idx ON table_x (org_id);

DROP TABLE IF EXISTS table_y CASCADE;
CREATE TABLE table_y (id serial NOT NULL, org_id varchar NULL
, y_0 int4 NOT NULL
, y_1 int4 NOT NULL
, y_2 int4 NOT NULL
, y_3 int4 NOT NULL
, y_4 int4 NOT NULL
, y_5 int4 NOT NULL
, y_6 int4 NOT NULL
, y_7 int4 NOT NULL
, y_8 int4 NOT NULL
, y_9 int4 NOT NULL
, y_10 int4 NOT NULL
, y_11 int4 NOT NULL
, y_12 int4 NOT NULL
, y_13 int4 NOT NULL
, y_14 int4 NOT NULL
, y_15 int4 NOT NULL
, y_16 int4 NOT NULL
, y_17 int4 NOT NULL
, y_18 int4 NOT NULL
, y_19 int4 NOT NULL
, y_20 int4 NOT NULL
, y_21 int4 NOT NULL
, y_22 int4 NOT NULL
, y_23 int4 NOT NULL
, y_24 int4 NOT NULL
, y_25 int4 NOT NULL
, y_26 int4 NOT NULL
, y_27 int4 NOT NULL
, y_28 int4 NOT NULL
, y_29 int4 NOT NULL
, y_30 int4 NOT NULL
, y_31 int4 NOT NULL
, y_32 int4 NOT NULL
, y_33 int4 NOT NULL
, y_34 int4 NOT NULL
, y_35 int4 NOT NULL
, y_36 int4 NOT NULL
, y_37 int4 NOT NULL
, y_38 int4 NOT NULL
, y_39 int4 NOT NULL
, y_40 int4 NOT NULL
, y_41 int4 NOT NULL
, y_42 int4 NOT NULL
, y_43 int4 NOT NULL
, y_44 int4 NOT NULL
, y_45 int4 NOT NULL
, y_46 int4 NOT NULL
, y_47 int4 NOT NULL
, y_48 int4 NOT NULL
, y_49 int4 NOT NULL
, CONSTRAINT table_y_pkey PRIMARY KEY (id));
CREATE INDEX table_y_idx ON table_y (org_id);

DROP TABLE IF EXISTS table_z CASCADE;
CREATE TABLE table_z (id serial NOT NULL, org_id varchar NULL
, z_0 int4 NOT NULL
, z_1 int4 NOT NULL
, z_2 int4 NOT NULL
, z_3 int4 NOT NULL
, z_4 int4 NOT NULL
, z_5 int4 NOT NULL
, z_6 int4 NOT NULL
, z_7 int4 NOT NULL
, z_8 int4 NOT NULL
, z_9 int4 NOT NULL
, z_10 int4 NOT NULL
, z_11 int4 NOT NULL
, z_12 int4 NOT NULL
, z_13 int4 NOT NULL
, z_14 int4 NOT NULL
, z_15 int4 NOT NULL
, z_16 int4 NOT NULL
, z_17 int4 NOT NULL
, z_18 int4 NOT NULL
, z_19 int4 NOT NULL
, z_20 int4 NOT NULL
, z_21 int4 NOT NULL
, z_22 int4 NOT NULL
, z_23 int4 NOT NULL
, z_24 int4 NOT NULL
, z_25 int4 NOT NULL
, z_26 int4 NOT NULL
, z_27 int4 NOT NULL
, z_28 int4 NOT NULL
, z_29 int4 NOT NULL
, z_30 int4 NOT NULL
, z_31 int4 NOT NULL
, z_32 int4 NOT NULL
, z_33 int4 NOT NULL
, z_34 int4 NOT NULL
, z_35 int4 NOT NULL
, z_36 int4 NOT NULL
, z_37 int4 NOT NULL
, z_38 int4 NOT NULL
, z_39 int4 NOT NULL
, z_40 int4 NOT NULL
, z_41 int4 NOT NULL
, z_42 int4 NOT NULL
, z_43 int4 NOT NULL
, z_44 int4 NOT NULL
, z_45 int4 NOT NULL
, z_46 int4 NOT NULL
, z_47 int4 NOT NULL
, z_48 int4 NOT NULL
, z_49 int4 NOT NULL
, z_50 int4 NOT NULL
, z_51 int4 NOT NULL
, z_52 int4 NOT NULL
, z_53 int4 NOT NULL
, z_54 int4 NOT NULL
, z_55 int4 NOT NULL
, z_56 int4 NOT NULL
, z_57 int4 NOT NULL
, z_58 int4 NOT NULL
, z_59 int4 NOT NULL
, z_60 int4 NOT NULL
, z_61 int4 NOT NULL
, z_62 int4 NOT NULL
, z_63 int4 NOT NULL
, z_64 int4 NOT NULL
, z_65 int4 NOT NULL
, z_66 int4 NOT NULL
, z_67 int4 NOT NULL
, z_68 int4 NOT NULL
, z_69 int4 NOT NULL
, z_70 int4 NOT NULL
, z_71 int4 NOT NULL
, z_72 int4 NOT NULL
, z_73 int4 NOT NULL
, z_74 int4 NOT NULL
, z_75 int4 NOT NULL
, z_76 int4 NOT NULL
, z_77 int4 NOT NULL
, z_78 int4 NOT NULL
, z_79 int4 NOT NULL
, z_80 int4 NOT NULL
, z_81 int4 NOT NULL
, z_82 int4 NOT NULL
, z_83 int4 NOT NULL
, z_84 int4 NOT NULL
, z_85 int4 NOT NULL
, z_86 int4 NOT NULL
, z_87 int4 NOT NULL
, z_88 int4 NOT NULL
, z_89 int4 NOT NULL
, z_90 int4 NOT NULL
, z_91 int4 NOT NULL
, z_92 int4 NOT NULL
, z_93 int4 NOT NULL
, z_94 int4 NOT NULL
, z_95 int4 NOT NULL
, z_96 int4 NOT NULL
, z_97 int4 NOT NULL
, z_98 int4 NOT NULL
, z_99 int4 NOT NULL
, z_100 int4 NOT NULL
, z_101 int4 NOT NULL
, z_102 int4 NOT NULL
, z_103 int4 NOT NULL
, z_104 int4 NOT NULL
, z_105 int4 NOT NULL
, z_106 int4 NOT NULL
, z_107 int4 NOT NULL
, z_108 int4 NOT NULL
, z_109 int4 NOT NULL
, z_110 int4 NOT NULL
, z_111 int4 NOT NULL
, z_112 int4 NOT NULL
, z_113 int4 NOT NULL
, z_114 int4 NOT NULL
, z_115 int4 NOT NULL
, z_116 int4 NOT NULL
, z_117 int4 NOT NULL
, z_118 int4 NOT NULL
, z_119 int4 NOT NULL
, z_120 int4 NOT NULL
, z_121 int4 NOT NULL
, z_122 int4 NOT NULL
, z_123 int4 NOT NULL
, z_124 int4 NOT NULL
, z_125 int4 NOT NULL
, z_126 int4 NOT NULL
, z_127 int4 NOT NULL
, z_128 int4 NOT NULL
, z_129 int4 NOT NULL
, z_130 int4 NOT NULL
, z_131 int4 NOT NULL
, z_132 int4 NOT NULL
, z_133 int4 NOT NULL
, z_134 int4 NOT NULL
, z_135 int4 NOT NULL
, z_136 int4 NOT NULL
, z_137 int4 NOT NULL
, z_138 int4 NOT NULL
, z_139 int4 NOT NULL
, z_140 int4 NOT NULL
, z_141 int4 NOT NULL
, z_142 int4 NOT NULL
, z_143 int4 NOT NULL
, z_144 int4 NOT NULL
, z_145 int4 NOT NULL
, z_146 int4 NOT NULL
, z_147 int4 NOT NULL
, z_148 int4 NOT NULL
, z_149 int4 NOT NULL
, CONSTRAINT table_z_pkey PRIMARY KEY (id));
CREATE INDEX table_z_idx ON table_z (org_id);

DROP TABLE IF EXISTS table_w CASCADE;
CREATE TABLE table_w (id serial NOT NULL, org_id varchar NULL
, w_0 int4 NOT NULL
, w_1 int4 NOT NULL
, w_2 int4 NOT NULL
, w_3 int4 NOT NULL
, w_4 int4 NOT NULL
, w_5 int4 NOT NULL
, w_6 int4 NOT NULL
, w_7 int4 NOT NULL
, w_8 int4 NOT NULL
, w_9 int4 NOT NULL
, w_10 int4 NOT NULL
, w_11 int4 NOT NULL
, w_12 int4 NOT NULL
, w_13 int4 NOT NULL
, w_14 int4 NOT NULL
, w_15 int4 NOT NULL
, w_16 int4 NOT NULL
, w_17 int4 NOT NULL
, w_18 int4 NOT NULL
, w_19 int4 NOT NULL
, w_20 int4 NOT NULL
, w_21 int4 NOT NULL
, w_22 int4 NOT NULL
, w_23 int4 NOT NULL
, w_24 int4 NOT NULL
, w_25 int4 NOT NULL
, w_26 int4 NOT NULL
, w_27 int4 NOT NULL
, w_28 int4 NOT NULL
, w_29 int4 NOT NULL
, w_30 int4 NOT NULL
, w_31 int4 NOT NULL
, w_32 int4 NOT NULL
, w_33 int4 NOT NULL
, w_34 int4 NOT NULL
, w_35 int4 NOT NULL
, w_36 int4 NOT NULL
, w_37 int4 NOT NULL
, w_38 int4 NOT NULL
, w_39 int4 NOT NULL
, w_40 int4 NOT NULL
, w_41 int4 NOT NULL
, w_42 int4 NOT NULL
, w_43 int4 NOT NULL
, w_44 int4 NOT NULL
, w_45 int4 NOT NULL
, w_46 int4 NOT NULL
, w_47 int4 NOT NULL
, w_48 int4 NOT NULL
, w_49 int4 NOT NULL
, w_50 int4 NOT NULL
, w_51 int4 NOT NULL
, w_52 int4 NOT NULL
, w_53 int4 NOT NULL
, w_54 int4 NOT NULL
, w_55 int4 NOT NULL
, w_56 int4 NOT NULL
, w_57 int4 NOT NULL
, w_58 int4 NOT NULL
, w_59 int4 NOT NULL
, w_60 int4 NOT NULL
, w_61 int4 NOT NULL
, w_62 int4 NOT NULL
, w_63 int4 NOT NULL
, w_64 int4 NOT NULL
, w_65 int4 NOT NULL
, w_66 int4 NOT NULL
, w_67 int4 NOT NULL
, w_68 int4 NOT NULL
, w_69 int4 NOT NULL
, w_70 int4 NOT NULL
, w_71 int4 NOT NULL
, w_72 int4 NOT NULL
, w_73 int4 NOT NULL
, w_74 int4 NOT NULL
, w_75 int4 NOT NULL
, w_76 int4 NOT NULL
, w_77 int4 NOT NULL
, w_78 int4 NOT NULL
, w_79 int4 NOT NULL
, w_80 int4 NOT NULL
, w_81 int4 NOT NULL
, w_82 int4 NOT NULL
, w_83 int4 NOT NULL
, w_84 int4 NOT NULL
, w_85 int4 NOT NULL
, w_86 int4 NOT NULL
, w_87 int4 NOT NULL
, w_88 int4 NOT NULL
, w_89 int4 NOT NULL
, w_90 int4 NOT NULL
, w_91 int4 NOT NULL
, w_92 int4 NOT NULL
, w_93 int4 NOT NULL
, w_94 int4 NOT NULL
, w_95 int4 NOT NULL
, w_96 int4 NOT NULL
, w_97 int4 NOT NULL
, w_98 int4 NOT NULL
, w_99 int4 NOT NULL
, w_100 int4 NOT NULL
, w_101 int4 NOT NULL
, w_102 int4 NOT NULL
, w_103 int4 NOT NULL
, w_104 int4 NOT NULL
, w_105 int4 NOT NULL
, w_106 int4 NOT NULL
, w_107 int4 NOT NULL
, w_108 int4 NOT NULL
, w_109 int4 NOT NULL
, w_110 int4 NOT NULL
, w_111 int4 NOT NULL
, w_112 int4 NOT NULL
, w_113 int4 NOT NULL
, w_114 int4 NOT NULL
, w_115 int4 NOT NULL
, w_116 int4 NOT NULL
, w_117 int4 NOT NULL
, w_118 int4 NOT NULL
, w_119 int4 NOT NULL
, w_120 int4 NOT NULL
, w_121 int4 NOT NULL
, w_122 int4 NOT NULL
, w_123 int4 NOT NULL
, w_124 int4 NOT NULL
, w_125 int4 NOT NULL
, w_126 int4 NOT NULL
, w_127 int4 NOT NULL
, w_128 int4 NOT NULL
, w_129 int4 NOT NULL
, w_130 int4 NOT NULL
, w_131 int4 NOT NULL
, w_132 int4 NOT NULL
, w_133 int4 NOT NULL
, w_134 int4 NOT NULL
, w_135 int4 NOT NULL
, w_136 int4 NOT NULL
, w_137 int4 NOT NULL
, w_138 int4 NOT NULL
, w_139 int4 NOT NULL
, w_140 int4 NOT NULL
, w_141 int4 NOT NULL
, w_142 int4 NOT NULL
, w_143 int4 NOT NULL
, w_144 int4 NOT NULL
, w_145 int4 NOT NULL
, w_146 int4 NOT NULL
, w_147 int4 NOT NULL
, w_148 int4 NOT NULL
, w_149 int4 NOT NULL
, CONSTRAINT table_w_pkey PRIMARY KEY (id));
CREATE INDEX table_w_idx ON table_w (org_id);


DROP FUNCTION IF EXISTS calcA(int4, int4) CASCADE;
CREATE FUNCTION calcA(value int4, mult int4)
RETURNS int4 AS $$
BEGIN
	RETURN value * mult;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS calcB(int4, int4) CASCADE;
CREATE FUNCTION calcB(value int4, sum int4)
RETURNS int4 AS $$
BEGIN
	RETURN value + sum;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS calcC(int4, int4) CASCADE;
CREATE FUNCTION calcC(value int4, mask int4)
RETURNS int4 AS $$
BEGIN
	RETURN value & mask;
END;
$$ LANGUAGE plpgsql;

DROP VIEW IF EXISTS table_x_view;
CREATE VIEW table_x_view AS
SELECT org_id
, calcA(x_0,1) x_0_alpha , calcA(x_0,2) x_0_beta , calcA(x_0,3) x_0_gamma , calcA(x_0,4) x_0_delta 
, calcA(x_1,1) x_1_alpha , calcA(x_1,2) x_1_beta , calcA(x_1,3) x_1_gamma , calcA(x_1,4) x_1_delta 
, calcA(x_2,1) x_2_alpha , calcA(x_2,2) x_2_beta , calcA(x_2,3) x_2_gamma , calcA(x_2,4) x_2_delta 
, calcA(x_3,1) x_3_alpha , calcA(x_3,2) x_3_beta , calcA(x_3,3) x_3_gamma , calcA(x_3,4) x_3_delta 
, calcA(x_4,1) x_4_alpha , calcA(x_4,2) x_4_beta , calcA(x_4,3) x_4_gamma , calcA(x_4,4) x_4_delta 
, calcA(x_5,1) x_5_alpha , calcA(x_5,2) x_5_beta , calcA(x_5,3) x_5_gamma , calcA(x_5,4) x_5_delta 
, calcA(x_6,1) x_6_alpha , calcA(x_6,2) x_6_beta , calcA(x_6,3) x_6_gamma , calcA(x_6,4) x_6_delta 
, calcA(x_7,1) x_7_alpha , calcA(x_7,2) x_7_beta , calcA(x_7,3) x_7_gamma , calcA(x_7,4) x_7_delta 
, calcA(x_8,1) x_8_alpha , calcA(x_8,2) x_8_beta , calcA(x_8,3) x_8_gamma , calcA(x_8,4) x_8_delta 
, calcA(x_9,1) x_9_alpha , calcA(x_9,2) x_9_beta , calcA(x_9,3) x_9_gamma , calcA(x_9,4) x_9_delta 
FROM table_x;

DROP VIEW IF EXISTS table_y_view;
CREATE VIEW table_y_view AS
SELECT org_id
, calcB(y_0,1) y_0_alpha , calcB(y_0,2) y_0_beta , calcB(y_0,3) y_0_gamma , calcB(y_0,4) y_0_delta 
, calcB(y_1,1) y_1_alpha , calcB(y_1,2) y_1_beta , calcB(y_1,3) y_1_gamma , calcB(y_1,4) y_1_delta 
, calcB(y_2,1) y_2_alpha , calcB(y_2,2) y_2_beta , calcB(y_2,3) y_2_gamma , calcB(y_2,4) y_2_delta 
, calcB(y_3,1) y_3_alpha , calcB(y_3,2) y_3_beta , calcB(y_3,3) y_3_gamma , calcB(y_3,4) y_3_delta 
, calcB(y_4,1) y_4_alpha , calcB(y_4,2) y_4_beta , calcB(y_4,3) y_4_gamma , calcB(y_4,4) y_4_delta 
, calcB(y_5,1) y_5_alpha , calcB(y_5,2) y_5_beta , calcB(y_5,3) y_5_gamma , calcB(y_5,4) y_5_delta 
, calcB(y_6,1) y_6_alpha , calcB(y_6,2) y_6_beta , calcB(y_6,3) y_6_gamma , calcB(y_6,4) y_6_delta 
, calcB(y_7,1) y_7_alpha , calcB(y_7,2) y_7_beta , calcB(y_7,3) y_7_gamma , calcB(y_7,4) y_7_delta 
, calcB(y_8,1) y_8_alpha , calcB(y_8,2) y_8_beta , calcB(y_8,3) y_8_gamma , calcB(y_8,4) y_8_delta 
, calcB(y_9,1) y_9_alpha , calcB(y_9,2) y_9_beta , calcB(y_9,3) y_9_gamma , calcB(y_9,4) y_9_delta 
, calcB(y_10,1) y_10_alpha , calcB(y_10,2) y_10_beta , calcB(y_10,3) y_10_gamma , calcB(y_10,4) y_10_delta 
, calcB(y_11,1) y_11_alpha , calcB(y_11,2) y_11_beta , calcB(y_11,3) y_11_gamma , calcB(y_11,4) y_11_delta 
, calcB(y_12,1) y_12_alpha , calcB(y_12,2) y_12_beta , calcB(y_12,3) y_12_gamma , calcB(y_12,4) y_12_delta 
, calcB(y_13,1) y_13_alpha , calcB(y_13,2) y_13_beta , calcB(y_13,3) y_13_gamma , calcB(y_13,4) y_13_delta 
, calcB(y_14,1) y_14_alpha , calcB(y_14,2) y_14_beta , calcB(y_14,3) y_14_gamma , calcB(y_14,4) y_14_delta 
, calcB(y_15,1) y_15_alpha , calcB(y_15,2) y_15_beta , calcB(y_15,3) y_15_gamma , calcB(y_15,4) y_15_delta 
, calcB(y_16,1) y_16_alpha , calcB(y_16,2) y_16_beta , calcB(y_16,3) y_16_gamma , calcB(y_16,4) y_16_delta 
, calcB(y_17,1) y_17_alpha , calcB(y_17,2) y_17_beta , calcB(y_17,3) y_17_gamma , calcB(y_17,4) y_17_delta 
, calcB(y_18,1) y_18_alpha , calcB(y_18,2) y_18_beta , calcB(y_18,3) y_18_gamma , calcB(y_18,4) y_18_delta 
, calcB(y_19,1) y_19_alpha , calcB(y_19,2) y_19_beta , calcB(y_19,3) y_19_gamma , calcB(y_19,4) y_19_delta 
, calcB(y_20,1) y_20_alpha , calcB(y_20,2) y_20_beta , calcB(y_20,3) y_20_gamma , calcB(y_20,4) y_20_delta 
, calcB(y_21,1) y_21_alpha , calcB(y_21,2) y_21_beta , calcB(y_21,3) y_21_gamma , calcB(y_21,4) y_21_delta 
, calcB(y_22,1) y_22_alpha , calcB(y_22,2) y_22_beta , calcB(y_22,3) y_22_gamma , calcB(y_22,4) y_22_delta 
, calcB(y_23,1) y_23_alpha , calcB(y_23,2) y_23_beta , calcB(y_23,3) y_23_gamma , calcB(y_23,4) y_23_delta 
, calcB(y_24,1) y_24_alpha , calcB(y_24,2) y_24_beta , calcB(y_24,3) y_24_gamma , calcB(y_24,4) y_24_delta 
, calcB(y_25,1) y_25_alpha , calcB(y_25,2) y_25_beta , calcB(y_25,3) y_25_gamma , calcB(y_25,4) y_25_delta 
, calcB(y_26,1) y_26_alpha , calcB(y_26,2) y_26_beta , calcB(y_26,3) y_26_gamma , calcB(y_26,4) y_26_delta 
, calcB(y_27,1) y_27_alpha , calcB(y_27,2) y_27_beta , calcB(y_27,3) y_27_gamma , calcB(y_27,4) y_27_delta 
, calcB(y_28,1) y_28_alpha , calcB(y_28,2) y_28_beta , calcB(y_28,3) y_28_gamma , calcB(y_28,4) y_28_delta 
, calcB(y_29,1) y_29_alpha , calcB(y_29,2) y_29_beta , calcB(y_29,3) y_29_gamma , calcB(y_29,4) y_29_delta 
, calcB(y_30,1) y_30_alpha , calcB(y_30,2) y_30_beta , calcB(y_30,3) y_30_gamma , calcB(y_30,4) y_30_delta 
, calcB(y_31,1) y_31_alpha , calcB(y_31,2) y_31_beta , calcB(y_31,3) y_31_gamma , calcB(y_31,4) y_31_delta 
, calcB(y_32,1) y_32_alpha , calcB(y_32,2) y_32_beta , calcB(y_32,3) y_32_gamma , calcB(y_32,4) y_32_delta 
, calcB(y_33,1) y_33_alpha , calcB(y_33,2) y_33_beta , calcB(y_33,3) y_33_gamma , calcB(y_33,4) y_33_delta 
, calcB(y_34,1) y_34_alpha , calcB(y_34,2) y_34_beta , calcB(y_34,3) y_34_gamma , calcB(y_34,4) y_34_delta 
, calcB(y_35,1) y_35_alpha , calcB(y_35,2) y_35_beta , calcB(y_35,3) y_35_gamma , calcB(y_35,4) y_35_delta 
, calcB(y_36,1) y_36_alpha , calcB(y_36,2) y_36_beta , calcB(y_36,3) y_36_gamma , calcB(y_36,4) y_36_delta 
, calcB(y_37,1) y_37_alpha , calcB(y_37,2) y_37_beta , calcB(y_37,3) y_37_gamma , calcB(y_37,4) y_37_delta 
, calcB(y_38,1) y_38_alpha , calcB(y_38,2) y_38_beta , calcB(y_38,3) y_38_gamma , calcB(y_38,4) y_38_delta 
, calcB(y_39,1) y_39_alpha , calcB(y_39,2) y_39_beta , calcB(y_39,3) y_39_gamma , calcB(y_39,4) y_39_delta 
, calcB(y_40,1) y_40_alpha , calcB(y_40,2) y_40_beta , calcB(y_40,3) y_40_gamma , calcB(y_40,4) y_40_delta 
, calcB(y_41,1) y_41_alpha , calcB(y_41,2) y_41_beta , calcB(y_41,3) y_41_gamma , calcB(y_41,4) y_41_delta 
, calcB(y_42,1) y_42_alpha , calcB(y_42,2) y_42_beta , calcB(y_42,3) y_42_gamma , calcB(y_42,4) y_42_delta 
, calcB(y_43,1) y_43_alpha , calcB(y_43,2) y_43_beta , calcB(y_43,3) y_43_gamma , calcB(y_43,4) y_43_delta 
, calcB(y_44,1) y_44_alpha , calcB(y_44,2) y_44_beta , calcB(y_44,3) y_44_gamma , calcB(y_44,4) y_44_delta 
, calcB(y_45,1) y_45_alpha , calcB(y_45,2) y_45_beta , calcB(y_45,3) y_45_gamma , calcB(y_45,4) y_45_delta 
, calcB(y_46,1) y_46_alpha , calcB(y_46,2) y_46_beta , calcB(y_46,3) y_46_gamma , calcB(y_46,4) y_46_delta 
, calcB(y_47,1) y_47_alpha , calcB(y_47,2) y_47_beta , calcB(y_47,3) y_47_gamma , calcB(y_47,4) y_47_delta 
, calcB(y_48,1) y_48_alpha , calcB(y_48,2) y_48_beta , calcB(y_48,3) y_48_gamma , calcB(y_48,4) y_48_delta 
, calcB(y_49,1) y_49_alpha , calcB(y_49,2) y_49_beta , calcB(y_49,3) y_49_gamma , calcB(y_49,4) y_49_delta 
FROM table_y;

DROP VIEW IF EXISTS table_z_view;
CREATE VIEW table_z_view AS
SELECT org_id
, calcC(z_0,1) z_0_alpha , calcC(z_0,2) z_0_beta , calcC(z_0,3) z_0_gamma , calcC(z_0,4) z_0_delta 
, calcC(z_1,1) z_1_alpha , calcC(z_1,2) z_1_beta , calcC(z_1,3) z_1_gamma , calcC(z_1,4) z_1_delta 
, calcC(z_2,1) z_2_alpha , calcC(z_2,2) z_2_beta , calcC(z_2,3) z_2_gamma , calcC(z_2,4) z_2_delta 
, calcC(z_3,1) z_3_alpha , calcC(z_3,2) z_3_beta , calcC(z_3,3) z_3_gamma , calcC(z_3,4) z_3_delta 
, calcC(z_4,1) z_4_alpha , calcC(z_4,2) z_4_beta , calcC(z_4,3) z_4_gamma , calcC(z_4,4) z_4_delta 
, calcC(z_5,1) z_5_alpha , calcC(z_5,2) z_5_beta , calcC(z_5,3) z_5_gamma , calcC(z_5,4) z_5_delta 
, calcC(z_6,1) z_6_alpha , calcC(z_6,2) z_6_beta , calcC(z_6,3) z_6_gamma , calcC(z_6,4) z_6_delta 
, calcC(z_7,1) z_7_alpha , calcC(z_7,2) z_7_beta , calcC(z_7,3) z_7_gamma , calcC(z_7,4) z_7_delta 
, calcC(z_8,1) z_8_alpha , calcC(z_8,2) z_8_beta , calcC(z_8,3) z_8_gamma , calcC(z_8,4) z_8_delta 
, calcC(z_9,1) z_9_alpha , calcC(z_9,2) z_9_beta , calcC(z_9,3) z_9_gamma , calcC(z_9,4) z_9_delta 
, calcC(z_10,1) z_10_alpha , calcC(z_10,2) z_10_beta , calcC(z_10,3) z_10_gamma , calcC(z_10,4) z_10_delta 
, calcC(z_11,1) z_11_alpha , calcC(z_11,2) z_11_beta , calcC(z_11,3) z_11_gamma , calcC(z_11,4) z_11_delta 
, calcC(z_12,1) z_12_alpha , calcC(z_12,2) z_12_beta , calcC(z_12,3) z_12_gamma , calcC(z_12,4) z_12_delta 
, calcC(z_13,1) z_13_alpha , calcC(z_13,2) z_13_beta , calcC(z_13,3) z_13_gamma , calcC(z_13,4) z_13_delta 
, calcC(z_14,1) z_14_alpha , calcC(z_14,2) z_14_beta , calcC(z_14,3) z_14_gamma , calcC(z_14,4) z_14_delta 
, calcC(z_15,1) z_15_alpha , calcC(z_15,2) z_15_beta , calcC(z_15,3) z_15_gamma , calcC(z_15,4) z_15_delta 
, calcC(z_16,1) z_16_alpha , calcC(z_16,2) z_16_beta , calcC(z_16,3) z_16_gamma , calcC(z_16,4) z_16_delta 
, calcC(z_17,1) z_17_alpha , calcC(z_17,2) z_17_beta , calcC(z_17,3) z_17_gamma , calcC(z_17,4) z_17_delta 
, calcC(z_18,1) z_18_alpha , calcC(z_18,2) z_18_beta , calcC(z_18,3) z_18_gamma , calcC(z_18,4) z_18_delta 
, calcC(z_19,1) z_19_alpha , calcC(z_19,2) z_19_beta , calcC(z_19,3) z_19_gamma , calcC(z_19,4) z_19_delta 
, calcC(z_20,1) z_20_alpha , calcC(z_20,2) z_20_beta , calcC(z_20,3) z_20_gamma , calcC(z_20,4) z_20_delta 
, calcC(z_21,1) z_21_alpha , calcC(z_21,2) z_21_beta , calcC(z_21,3) z_21_gamma , calcC(z_21,4) z_21_delta 
, calcC(z_22,1) z_22_alpha , calcC(z_22,2) z_22_beta , calcC(z_22,3) z_22_gamma , calcC(z_22,4) z_22_delta 
, calcC(z_23,1) z_23_alpha , calcC(z_23,2) z_23_beta , calcC(z_23,3) z_23_gamma , calcC(z_23,4) z_23_delta 
, calcC(z_24,1) z_24_alpha , calcC(z_24,2) z_24_beta , calcC(z_24,3) z_24_gamma , calcC(z_24,4) z_24_delta 
, calcC(z_25,1) z_25_alpha , calcC(z_25,2) z_25_beta , calcC(z_25,3) z_25_gamma , calcC(z_25,4) z_25_delta 
, calcC(z_26,1) z_26_alpha , calcC(z_26,2) z_26_beta , calcC(z_26,3) z_26_gamma , calcC(z_26,4) z_26_delta 
, calcC(z_27,1) z_27_alpha , calcC(z_27,2) z_27_beta , calcC(z_27,3) z_27_gamma , calcC(z_27,4) z_27_delta 
, calcC(z_28,1) z_28_alpha , calcC(z_28,2) z_28_beta , calcC(z_28,3) z_28_gamma , calcC(z_28,4) z_28_delta 
, calcC(z_29,1) z_29_alpha , calcC(z_29,2) z_29_beta , calcC(z_29,3) z_29_gamma , calcC(z_29,4) z_29_delta 
, calcC(z_30,1) z_30_alpha , calcC(z_30,2) z_30_beta , calcC(z_30,3) z_30_gamma , calcC(z_30,4) z_30_delta 
, calcC(z_31,1) z_31_alpha , calcC(z_31,2) z_31_beta , calcC(z_31,3) z_31_gamma , calcC(z_31,4) z_31_delta 
, calcC(z_32,1) z_32_alpha , calcC(z_32,2) z_32_beta , calcC(z_32,3) z_32_gamma , calcC(z_32,4) z_32_delta 
, calcC(z_33,1) z_33_alpha , calcC(z_33,2) z_33_beta , calcC(z_33,3) z_33_gamma , calcC(z_33,4) z_33_delta 
, calcC(z_34,1) z_34_alpha , calcC(z_34,2) z_34_beta , calcC(z_34,3) z_34_gamma , calcC(z_34,4) z_34_delta 
, calcC(z_35,1) z_35_alpha , calcC(z_35,2) z_35_beta , calcC(z_35,3) z_35_gamma , calcC(z_35,4) z_35_delta 
, calcC(z_36,1) z_36_alpha , calcC(z_36,2) z_36_beta , calcC(z_36,3) z_36_gamma , calcC(z_36,4) z_36_delta 
, calcC(z_37,1) z_37_alpha , calcC(z_37,2) z_37_beta , calcC(z_37,3) z_37_gamma , calcC(z_37,4) z_37_delta 
, calcC(z_38,1) z_38_alpha , calcC(z_38,2) z_38_beta , calcC(z_38,3) z_38_gamma , calcC(z_38,4) z_38_delta 
, calcC(z_39,1) z_39_alpha , calcC(z_39,2) z_39_beta , calcC(z_39,3) z_39_gamma , calcC(z_39,4) z_39_delta 
, calcC(z_40,1) z_40_alpha , calcC(z_40,2) z_40_beta , calcC(z_40,3) z_40_gamma , calcC(z_40,4) z_40_delta 
, calcC(z_41,1) z_41_alpha , calcC(z_41,2) z_41_beta , calcC(z_41,3) z_41_gamma , calcC(z_41,4) z_41_delta 
, calcC(z_42,1) z_42_alpha , calcC(z_42,2) z_42_beta , calcC(z_42,3) z_42_gamma , calcC(z_42,4) z_42_delta 
, calcC(z_43,1) z_43_alpha , calcC(z_43,2) z_43_beta , calcC(z_43,3) z_43_gamma , calcC(z_43,4) z_43_delta 
, calcC(z_44,1) z_44_alpha , calcC(z_44,2) z_44_beta , calcC(z_44,3) z_44_gamma , calcC(z_44,4) z_44_delta 
, calcC(z_45,1) z_45_alpha , calcC(z_45,2) z_45_beta , calcC(z_45,3) z_45_gamma , calcC(z_45,4) z_45_delta 
, calcC(z_46,1) z_46_alpha , calcC(z_46,2) z_46_beta , calcC(z_46,3) z_46_gamma , calcC(z_46,4) z_46_delta 
, calcC(z_47,1) z_47_alpha , calcC(z_47,2) z_47_beta , calcC(z_47,3) z_47_gamma , calcC(z_47,4) z_47_delta 
, calcC(z_48,1) z_48_alpha , calcC(z_48,2) z_48_beta , calcC(z_48,3) z_48_gamma , calcC(z_48,4) z_48_delta 
, calcC(z_49,1) z_49_alpha , calcC(z_49,2) z_49_beta , calcC(z_49,3) z_49_gamma , calcC(z_49,4) z_49_delta 
, calcC(z_50,1) z_50_alpha , calcC(z_50,2) z_50_beta , calcC(z_50,3) z_50_gamma , calcC(z_50,4) z_50_delta 
, calcC(z_51,1) z_51_alpha , calcC(z_51,2) z_51_beta , calcC(z_51,3) z_51_gamma , calcC(z_51,4) z_51_delta 
, calcC(z_52,1) z_52_alpha , calcC(z_52,2) z_52_beta , calcC(z_52,3) z_52_gamma , calcC(z_52,4) z_52_delta 
, calcC(z_53,1) z_53_alpha , calcC(z_53,2) z_53_beta , calcC(z_53,3) z_53_gamma , calcC(z_53,4) z_53_delta 
, calcC(z_54,1) z_54_alpha , calcC(z_54,2) z_54_beta , calcC(z_54,3) z_54_gamma , calcC(z_54,4) z_54_delta 
, calcC(z_55,1) z_55_alpha , calcC(z_55,2) z_55_beta , calcC(z_55,3) z_55_gamma , calcC(z_55,4) z_55_delta 
, calcC(z_56,1) z_56_alpha , calcC(z_56,2) z_56_beta , calcC(z_56,3) z_56_gamma , calcC(z_56,4) z_56_delta 
, calcC(z_57,1) z_57_alpha , calcC(z_57,2) z_57_beta , calcC(z_57,3) z_57_gamma , calcC(z_57,4) z_57_delta 
, calcC(z_58,1) z_58_alpha , calcC(z_58,2) z_58_beta , calcC(z_58,3) z_58_gamma , calcC(z_58,4) z_58_delta 
, calcC(z_59,1) z_59_alpha , calcC(z_59,2) z_59_beta , calcC(z_59,3) z_59_gamma , calcC(z_59,4) z_59_delta 
, calcC(z_60,1) z_60_alpha , calcC(z_60,2) z_60_beta , calcC(z_60,3) z_60_gamma , calcC(z_60,4) z_60_delta 
, calcC(z_61,1) z_61_alpha , calcC(z_61,2) z_61_beta , calcC(z_61,3) z_61_gamma , calcC(z_61,4) z_61_delta 
, calcC(z_62,1) z_62_alpha , calcC(z_62,2) z_62_beta , calcC(z_62,3) z_62_gamma , calcC(z_62,4) z_62_delta 
, calcC(z_63,1) z_63_alpha , calcC(z_63,2) z_63_beta , calcC(z_63,3) z_63_gamma , calcC(z_63,4) z_63_delta 
, calcC(z_64,1) z_64_alpha , calcC(z_64,2) z_64_beta , calcC(z_64,3) z_64_gamma , calcC(z_64,4) z_64_delta 
, calcC(z_65,1) z_65_alpha , calcC(z_65,2) z_65_beta , calcC(z_65,3) z_65_gamma , calcC(z_65,4) z_65_delta 
, calcC(z_66,1) z_66_alpha , calcC(z_66,2) z_66_beta , calcC(z_66,3) z_66_gamma , calcC(z_66,4) z_66_delta 
, calcC(z_67,1) z_67_alpha , calcC(z_67,2) z_67_beta , calcC(z_67,3) z_67_gamma , calcC(z_67,4) z_67_delta 
, calcC(z_68,1) z_68_alpha , calcC(z_68,2) z_68_beta , calcC(z_68,3) z_68_gamma , calcC(z_68,4) z_68_delta 
, calcC(z_69,1) z_69_alpha , calcC(z_69,2) z_69_beta , calcC(z_69,3) z_69_gamma , calcC(z_69,4) z_69_delta 
, calcC(z_70,1) z_70_alpha , calcC(z_70,2) z_70_beta , calcC(z_70,3) z_70_gamma , calcC(z_70,4) z_70_delta 
, calcC(z_71,1) z_71_alpha , calcC(z_71,2) z_71_beta , calcC(z_71,3) z_71_gamma , calcC(z_71,4) z_71_delta 
, calcC(z_72,1) z_72_alpha , calcC(z_72,2) z_72_beta , calcC(z_72,3) z_72_gamma , calcC(z_72,4) z_72_delta 
, calcC(z_73,1) z_73_alpha , calcC(z_73,2) z_73_beta , calcC(z_73,3) z_73_gamma , calcC(z_73,4) z_73_delta 
, calcC(z_74,1) z_74_alpha , calcC(z_74,2) z_74_beta , calcC(z_74,3) z_74_gamma , calcC(z_74,4) z_74_delta 
, calcC(z_75,1) z_75_alpha , calcC(z_75,2) z_75_beta , calcC(z_75,3) z_75_gamma , calcC(z_75,4) z_75_delta 
, calcC(z_76,1) z_76_alpha , calcC(z_76,2) z_76_beta , calcC(z_76,3) z_76_gamma , calcC(z_76,4) z_76_delta 
, calcC(z_77,1) z_77_alpha , calcC(z_77,2) z_77_beta , calcC(z_77,3) z_77_gamma , calcC(z_77,4) z_77_delta 
, calcC(z_78,1) z_78_alpha , calcC(z_78,2) z_78_beta , calcC(z_78,3) z_78_gamma , calcC(z_78,4) z_78_delta 
, calcC(z_79,1) z_79_alpha , calcC(z_79,2) z_79_beta , calcC(z_79,3) z_79_gamma , calcC(z_79,4) z_79_delta 
, calcC(z_80,1) z_80_alpha , calcC(z_80,2) z_80_beta , calcC(z_80,3) z_80_gamma , calcC(z_80,4) z_80_delta 
, calcC(z_81,1) z_81_alpha , calcC(z_81,2) z_81_beta , calcC(z_81,3) z_81_gamma , calcC(z_81,4) z_81_delta 
, calcC(z_82,1) z_82_alpha , calcC(z_82,2) z_82_beta , calcC(z_82,3) z_82_gamma , calcC(z_82,4) z_82_delta 
, calcC(z_83,1) z_83_alpha , calcC(z_83,2) z_83_beta , calcC(z_83,3) z_83_gamma , calcC(z_83,4) z_83_delta 
, calcC(z_84,1) z_84_alpha , calcC(z_84,2) z_84_beta , calcC(z_84,3) z_84_gamma , calcC(z_84,4) z_84_delta 
, calcC(z_85,1) z_85_alpha , calcC(z_85,2) z_85_beta , calcC(z_85,3) z_85_gamma , calcC(z_85,4) z_85_delta 
, calcC(z_86,1) z_86_alpha , calcC(z_86,2) z_86_beta , calcC(z_86,3) z_86_gamma , calcC(z_86,4) z_86_delta 
, calcC(z_87,1) z_87_alpha , calcC(z_87,2) z_87_beta , calcC(z_87,3) z_87_gamma , calcC(z_87,4) z_87_delta 
, calcC(z_88,1) z_88_alpha , calcC(z_88,2) z_88_beta , calcC(z_88,3) z_88_gamma , calcC(z_88,4) z_88_delta 
, calcC(z_89,1) z_89_alpha , calcC(z_89,2) z_89_beta , calcC(z_89,3) z_89_gamma , calcC(z_89,4) z_89_delta 
, calcC(z_90,1) z_90_alpha , calcC(z_90,2) z_90_beta , calcC(z_90,3) z_90_gamma , calcC(z_90,4) z_90_delta 
, calcC(z_91,1) z_91_alpha , calcC(z_91,2) z_91_beta , calcC(z_91,3) z_91_gamma , calcC(z_91,4) z_91_delta 
, calcC(z_92,1) z_92_alpha , calcC(z_92,2) z_92_beta , calcC(z_92,3) z_92_gamma , calcC(z_92,4) z_92_delta 
, calcC(z_93,1) z_93_alpha , calcC(z_93,2) z_93_beta , calcC(z_93,3) z_93_gamma , calcC(z_93,4) z_93_delta 
, calcC(z_94,1) z_94_alpha , calcC(z_94,2) z_94_beta , calcC(z_94,3) z_94_gamma , calcC(z_94,4) z_94_delta 
, calcC(z_95,1) z_95_alpha , calcC(z_95,2) z_95_beta , calcC(z_95,3) z_95_gamma , calcC(z_95,4) z_95_delta 
, calcC(z_96,1) z_96_alpha , calcC(z_96,2) z_96_beta , calcC(z_96,3) z_96_gamma , calcC(z_96,4) z_96_delta 
, calcC(z_97,1) z_97_alpha , calcC(z_97,2) z_97_beta , calcC(z_97,3) z_97_gamma , calcC(z_97,4) z_97_delta 
, calcC(z_98,1) z_98_alpha , calcC(z_98,2) z_98_beta , calcC(z_98,3) z_98_gamma , calcC(z_98,4) z_98_delta 
, calcC(z_99,1) z_99_alpha , calcC(z_99,2) z_99_beta , calcC(z_99,3) z_99_gamma , calcC(z_99,4) z_99_delta 
, calcC(z_100,1) z_100_alpha , calcC(z_100,2) z_100_beta , calcC(z_100,3) z_100_gamma , calcC(z_100,4) z_100_delta 
, calcC(z_101,1) z_101_alpha , calcC(z_101,2) z_101_beta , calcC(z_101,3) z_101_gamma , calcC(z_101,4) z_101_delta 
, calcC(z_102,1) z_102_alpha , calcC(z_102,2) z_102_beta , calcC(z_102,3) z_102_gamma , calcC(z_102,4) z_102_delta 
, calcC(z_103,1) z_103_alpha , calcC(z_103,2) z_103_beta , calcC(z_103,3) z_103_gamma , calcC(z_103,4) z_103_delta 
, calcC(z_104,1) z_104_alpha , calcC(z_104,2) z_104_beta , calcC(z_104,3) z_104_gamma , calcC(z_104,4) z_104_delta 
, calcC(z_105,1) z_105_alpha , calcC(z_105,2) z_105_beta , calcC(z_105,3) z_105_gamma , calcC(z_105,4) z_105_delta 
, calcC(z_106,1) z_106_alpha , calcC(z_106,2) z_106_beta , calcC(z_106,3) z_106_gamma , calcC(z_106,4) z_106_delta 
, calcC(z_107,1) z_107_alpha , calcC(z_107,2) z_107_beta , calcC(z_107,3) z_107_gamma , calcC(z_107,4) z_107_delta 
, calcC(z_108,1) z_108_alpha , calcC(z_108,2) z_108_beta , calcC(z_108,3) z_108_gamma , calcC(z_108,4) z_108_delta 
, calcC(z_109,1) z_109_alpha , calcC(z_109,2) z_109_beta , calcC(z_109,3) z_109_gamma , calcC(z_109,4) z_109_delta 
, calcC(z_110,1) z_110_alpha , calcC(z_110,2) z_110_beta , calcC(z_110,3) z_110_gamma , calcC(z_110,4) z_110_delta 
, calcC(z_111,1) z_111_alpha , calcC(z_111,2) z_111_beta , calcC(z_111,3) z_111_gamma , calcC(z_111,4) z_111_delta 
, calcC(z_112,1) z_112_alpha , calcC(z_112,2) z_112_beta , calcC(z_112,3) z_112_gamma , calcC(z_112,4) z_112_delta 
, calcC(z_113,1) z_113_alpha , calcC(z_113,2) z_113_beta , calcC(z_113,3) z_113_gamma , calcC(z_113,4) z_113_delta 
, calcC(z_114,1) z_114_alpha , calcC(z_114,2) z_114_beta , calcC(z_114,3) z_114_gamma , calcC(z_114,4) z_114_delta 
, calcC(z_115,1) z_115_alpha , calcC(z_115,2) z_115_beta , calcC(z_115,3) z_115_gamma , calcC(z_115,4) z_115_delta 
, calcC(z_116,1) z_116_alpha , calcC(z_116,2) z_116_beta , calcC(z_116,3) z_116_gamma , calcC(z_116,4) z_116_delta 
, calcC(z_117,1) z_117_alpha , calcC(z_117,2) z_117_beta , calcC(z_117,3) z_117_gamma , calcC(z_117,4) z_117_delta 
, calcC(z_118,1) z_118_alpha , calcC(z_118,2) z_118_beta , calcC(z_118,3) z_118_gamma , calcC(z_118,4) z_118_delta 
, calcC(z_119,1) z_119_alpha , calcC(z_119,2) z_119_beta , calcC(z_119,3) z_119_gamma , calcC(z_119,4) z_119_delta 
, calcC(z_120,1) z_120_alpha , calcC(z_120,2) z_120_beta , calcC(z_120,3) z_120_gamma , calcC(z_120,4) z_120_delta 
, calcC(z_121,1) z_121_alpha , calcC(z_121,2) z_121_beta , calcC(z_121,3) z_121_gamma , calcC(z_121,4) z_121_delta 
, calcC(z_122,1) z_122_alpha , calcC(z_122,2) z_122_beta , calcC(z_122,3) z_122_gamma , calcC(z_122,4) z_122_delta 
, calcC(z_123,1) z_123_alpha , calcC(z_123,2) z_123_beta , calcC(z_123,3) z_123_gamma , calcC(z_123,4) z_123_delta 
, calcC(z_124,1) z_124_alpha , calcC(z_124,2) z_124_beta , calcC(z_124,3) z_124_gamma , calcC(z_124,4) z_124_delta 
, calcC(z_125,1) z_125_alpha , calcC(z_125,2) z_125_beta , calcC(z_125,3) z_125_gamma , calcC(z_125,4) z_125_delta 
, calcC(z_126,1) z_126_alpha , calcC(z_126,2) z_126_beta , calcC(z_126,3) z_126_gamma , calcC(z_126,4) z_126_delta 
, calcC(z_127,1) z_127_alpha , calcC(z_127,2) z_127_beta , calcC(z_127,3) z_127_gamma , calcC(z_127,4) z_127_delta 
, calcC(z_128,1) z_128_alpha , calcC(z_128,2) z_128_beta , calcC(z_128,3) z_128_gamma , calcC(z_128,4) z_128_delta 
, calcC(z_129,1) z_129_alpha , calcC(z_129,2) z_129_beta , calcC(z_129,3) z_129_gamma , calcC(z_129,4) z_129_delta 
, calcC(z_130,1) z_130_alpha , calcC(z_130,2) z_130_beta , calcC(z_130,3) z_130_gamma , calcC(z_130,4) z_130_delta 
, calcC(z_131,1) z_131_alpha , calcC(z_131,2) z_131_beta , calcC(z_131,3) z_131_gamma , calcC(z_131,4) z_131_delta 
, calcC(z_132,1) z_132_alpha , calcC(z_132,2) z_132_beta , calcC(z_132,3) z_132_gamma , calcC(z_132,4) z_132_delta 
, calcC(z_133,1) z_133_alpha , calcC(z_133,2) z_133_beta , calcC(z_133,3) z_133_gamma , calcC(z_133,4) z_133_delta 
, calcC(z_134,1) z_134_alpha , calcC(z_134,2) z_134_beta , calcC(z_134,3) z_134_gamma , calcC(z_134,4) z_134_delta 
, calcC(z_135,1) z_135_alpha , calcC(z_135,2) z_135_beta , calcC(z_135,3) z_135_gamma , calcC(z_135,4) z_135_delta 
, calcC(z_136,1) z_136_alpha , calcC(z_136,2) z_136_beta , calcC(z_136,3) z_136_gamma , calcC(z_136,4) z_136_delta 
, calcC(z_137,1) z_137_alpha , calcC(z_137,2) z_137_beta , calcC(z_137,3) z_137_gamma , calcC(z_137,4) z_137_delta 
, calcC(z_138,1) z_138_alpha , calcC(z_138,2) z_138_beta , calcC(z_138,3) z_138_gamma , calcC(z_138,4) z_138_delta 
, calcC(z_139,1) z_139_alpha , calcC(z_139,2) z_139_beta , calcC(z_139,3) z_139_gamma , calcC(z_139,4) z_139_delta 
, calcC(z_140,1) z_140_alpha , calcC(z_140,2) z_140_beta , calcC(z_140,3) z_140_gamma , calcC(z_140,4) z_140_delta 
, calcC(z_141,1) z_141_alpha , calcC(z_141,2) z_141_beta , calcC(z_141,3) z_141_gamma , calcC(z_141,4) z_141_delta 
, calcC(z_142,1) z_142_alpha , calcC(z_142,2) z_142_beta , calcC(z_142,3) z_142_gamma , calcC(z_142,4) z_142_delta 
, calcC(z_143,1) z_143_alpha , calcC(z_143,2) z_143_beta , calcC(z_143,3) z_143_gamma , calcC(z_143,4) z_143_delta 
, calcC(z_144,1) z_144_alpha , calcC(z_144,2) z_144_beta , calcC(z_144,3) z_144_gamma , calcC(z_144,4) z_144_delta 
, calcC(z_145,1) z_145_alpha , calcC(z_145,2) z_145_beta , calcC(z_145,3) z_145_gamma , calcC(z_145,4) z_145_delta 
, calcC(z_146,1) z_146_alpha , calcC(z_146,2) z_146_beta , calcC(z_146,3) z_146_gamma , calcC(z_146,4) z_146_delta 
, calcC(z_147,1) z_147_alpha , calcC(z_147,2) z_147_beta , calcC(z_147,3) z_147_gamma , calcC(z_147,4) z_147_delta 
, calcC(z_148,1) z_148_alpha , calcC(z_148,2) z_148_beta , calcC(z_148,3) z_148_gamma , calcC(z_148,4) z_148_delta 
, calcC(z_149,1) z_149_alpha , calcC(z_149,2) z_149_beta , calcC(z_149,3) z_149_gamma , calcC(z_149,4) z_149_delta 
FROM table_z;

DROP VIEW IF EXISTS table_w_view;
CREATE VIEW table_w_view AS
SELECT org_id
, calcC(w_0,1) w_0_alpha , calcC(w_0,2) w_0_beta , calcC(w_0,3) w_0_gamma , calcC(w_0,4) w_0_delta 
, calcC(w_1,1) w_1_alpha , calcC(w_1,2) w_1_beta , calcC(w_1,3) w_1_gamma , calcC(w_1,4) w_1_delta 
, calcC(w_2,1) w_2_alpha , calcC(w_2,2) w_2_beta , calcC(w_2,3) w_2_gamma , calcC(w_2,4) w_2_delta 
, calcC(w_3,1) w_3_alpha , calcC(w_3,2) w_3_beta , calcC(w_3,3) w_3_gamma , calcC(w_3,4) w_3_delta 
, calcC(w_4,1) w_4_alpha , calcC(w_4,2) w_4_beta , calcC(w_4,3) w_4_gamma , calcC(w_4,4) w_4_delta 
, calcC(w_5,1) w_5_alpha , calcC(w_5,2) w_5_beta , calcC(w_5,3) w_5_gamma , calcC(w_5,4) w_5_delta 
, calcC(w_6,1) w_6_alpha , calcC(w_6,2) w_6_beta , calcC(w_6,3) w_6_gamma , calcC(w_6,4) w_6_delta 
, calcC(w_7,1) w_7_alpha , calcC(w_7,2) w_7_beta , calcC(w_7,3) w_7_gamma , calcC(w_7,4) w_7_delta 
, calcC(w_8,1) w_8_alpha , calcC(w_8,2) w_8_beta , calcC(w_8,3) w_8_gamma , calcC(w_8,4) w_8_delta 
, calcC(w_9,1) w_9_alpha , calcC(w_9,2) w_9_beta , calcC(w_9,3) w_9_gamma , calcC(w_9,4) w_9_delta 
, calcC(w_10,1) w_10_alpha , calcC(w_10,2) w_10_beta , calcC(w_10,3) w_10_gamma , calcC(w_10,4) w_10_delta 
, calcC(w_11,1) w_11_alpha , calcC(w_11,2) w_11_beta , calcC(w_11,3) w_11_gamma , calcC(w_11,4) w_11_delta 
, calcC(w_12,1) w_12_alpha , calcC(w_12,2) w_12_beta , calcC(w_12,3) w_12_gamma , calcC(w_12,4) w_12_delta 
, calcC(w_13,1) w_13_alpha , calcC(w_13,2) w_13_beta , calcC(w_13,3) w_13_gamma , calcC(w_13,4) w_13_delta 
, calcC(w_14,1) w_14_alpha , calcC(w_14,2) w_14_beta , calcC(w_14,3) w_14_gamma , calcC(w_14,4) w_14_delta 
, calcC(w_15,1) w_15_alpha , calcC(w_15,2) w_15_beta , calcC(w_15,3) w_15_gamma , calcC(w_15,4) w_15_delta 
, calcC(w_16,1) w_16_alpha , calcC(w_16,2) w_16_beta , calcC(w_16,3) w_16_gamma , calcC(w_16,4) w_16_delta 
, calcC(w_17,1) w_17_alpha , calcC(w_17,2) w_17_beta , calcC(w_17,3) w_17_gamma , calcC(w_17,4) w_17_delta 
, calcC(w_18,1) w_18_alpha , calcC(w_18,2) w_18_beta , calcC(w_18,3) w_18_gamma , calcC(w_18,4) w_18_delta 
, calcC(w_19,1) w_19_alpha , calcC(w_19,2) w_19_beta , calcC(w_19,3) w_19_gamma , calcC(w_19,4) w_19_delta 
, calcC(w_20,1) w_20_alpha , calcC(w_20,2) w_20_beta , calcC(w_20,3) w_20_gamma , calcC(w_20,4) w_20_delta 
, calcC(w_21,1) w_21_alpha , calcC(w_21,2) w_21_beta , calcC(w_21,3) w_21_gamma , calcC(w_21,4) w_21_delta 
, calcC(w_22,1) w_22_alpha , calcC(w_22,2) w_22_beta , calcC(w_22,3) w_22_gamma , calcC(w_22,4) w_22_delta 
, calcC(w_23,1) w_23_alpha , calcC(w_23,2) w_23_beta , calcC(w_23,3) w_23_gamma , calcC(w_23,4) w_23_delta 
, calcC(w_24,1) w_24_alpha , calcC(w_24,2) w_24_beta , calcC(w_24,3) w_24_gamma , calcC(w_24,4) w_24_delta 
, calcC(w_25,1) w_25_alpha , calcC(w_25,2) w_25_beta , calcC(w_25,3) w_25_gamma , calcC(w_25,4) w_25_delta 
, calcC(w_26,1) w_26_alpha , calcC(w_26,2) w_26_beta , calcC(w_26,3) w_26_gamma , calcC(w_26,4) w_26_delta 
, calcC(w_27,1) w_27_alpha , calcC(w_27,2) w_27_beta , calcC(w_27,3) w_27_gamma , calcC(w_27,4) w_27_delta 
, calcC(w_28,1) w_28_alpha , calcC(w_28,2) w_28_beta , calcC(w_28,3) w_28_gamma , calcC(w_28,4) w_28_delta 
, calcC(w_29,1) w_29_alpha , calcC(w_29,2) w_29_beta , calcC(w_29,3) w_29_gamma , calcC(w_29,4) w_29_delta 
, calcC(w_30,1) w_30_alpha , calcC(w_30,2) w_30_beta , calcC(w_30,3) w_30_gamma , calcC(w_30,4) w_30_delta 
, calcC(w_31,1) w_31_alpha , calcC(w_31,2) w_31_beta , calcC(w_31,3) w_31_gamma , calcC(w_31,4) w_31_delta 
, calcC(w_32,1) w_32_alpha , calcC(w_32,2) w_32_beta , calcC(w_32,3) w_32_gamma , calcC(w_32,4) w_32_delta 
, calcC(w_33,1) w_33_alpha , calcC(w_33,2) w_33_beta , calcC(w_33,3) w_33_gamma , calcC(w_33,4) w_33_delta 
, calcC(w_34,1) w_34_alpha , calcC(w_34,2) w_34_beta , calcC(w_34,3) w_34_gamma , calcC(w_34,4) w_34_delta 
, calcC(w_35,1) w_35_alpha , calcC(w_35,2) w_35_beta , calcC(w_35,3) w_35_gamma , calcC(w_35,4) w_35_delta 
, calcC(w_36,1) w_36_alpha , calcC(w_36,2) w_36_beta , calcC(w_36,3) w_36_gamma , calcC(w_36,4) w_36_delta 
, calcC(w_37,1) w_37_alpha , calcC(w_37,2) w_37_beta , calcC(w_37,3) w_37_gamma , calcC(w_37,4) w_37_delta 
, calcC(w_38,1) w_38_alpha , calcC(w_38,2) w_38_beta , calcC(w_38,3) w_38_gamma , calcC(w_38,4) w_38_delta 
, calcC(w_39,1) w_39_alpha , calcC(w_39,2) w_39_beta , calcC(w_39,3) w_39_gamma , calcC(w_39,4) w_39_delta 
, calcC(w_40,1) w_40_alpha , calcC(w_40,2) w_40_beta , calcC(w_40,3) w_40_gamma , calcC(w_40,4) w_40_delta 
, calcC(w_41,1) w_41_alpha , calcC(w_41,2) w_41_beta , calcC(w_41,3) w_41_gamma , calcC(w_41,4) w_41_delta 
, calcC(w_42,1) w_42_alpha , calcC(w_42,2) w_42_beta , calcC(w_42,3) w_42_gamma , calcC(w_42,4) w_42_delta 
, calcC(w_43,1) w_43_alpha , calcC(w_43,2) w_43_beta , calcC(w_43,3) w_43_gamma , calcC(w_43,4) w_43_delta 
, calcC(w_44,1) w_44_alpha , calcC(w_44,2) w_44_beta , calcC(w_44,3) w_44_gamma , calcC(w_44,4) w_44_delta 
, calcC(w_45,1) w_45_alpha , calcC(w_45,2) w_45_beta , calcC(w_45,3) w_45_gamma , calcC(w_45,4) w_45_delta 
, calcC(w_46,1) w_46_alpha , calcC(w_46,2) w_46_beta , calcC(w_46,3) w_46_gamma , calcC(w_46,4) w_46_delta 
, calcC(w_47,1) w_47_alpha , calcC(w_47,2) w_47_beta , calcC(w_47,3) w_47_gamma , calcC(w_47,4) w_47_delta 
, calcC(w_48,1) w_48_alpha , calcC(w_48,2) w_48_beta , calcC(w_48,3) w_48_gamma , calcC(w_48,4) w_48_delta 
, calcC(w_49,1) w_49_alpha , calcC(w_49,2) w_49_beta , calcC(w_49,3) w_49_gamma , calcC(w_49,4) w_49_delta 
, calcC(w_50,1) w_50_alpha , calcC(w_50,2) w_50_beta , calcC(w_50,3) w_50_gamma , calcC(w_50,4) w_50_delta 
, calcC(w_51,1) w_51_alpha , calcC(w_51,2) w_51_beta , calcC(w_51,3) w_51_gamma , calcC(w_51,4) w_51_delta 
, calcC(w_52,1) w_52_alpha , calcC(w_52,2) w_52_beta , calcC(w_52,3) w_52_gamma , calcC(w_52,4) w_52_delta 
, calcC(w_53,1) w_53_alpha , calcC(w_53,2) w_53_beta , calcC(w_53,3) w_53_gamma , calcC(w_53,4) w_53_delta 
, calcC(w_54,1) w_54_alpha , calcC(w_54,2) w_54_beta , calcC(w_54,3) w_54_gamma , calcC(w_54,4) w_54_delta 
, calcC(w_55,1) w_55_alpha , calcC(w_55,2) w_55_beta , calcC(w_55,3) w_55_gamma , calcC(w_55,4) w_55_delta 
, calcC(w_56,1) w_56_alpha , calcC(w_56,2) w_56_beta , calcC(w_56,3) w_56_gamma , calcC(w_56,4) w_56_delta 
, calcC(w_57,1) w_57_alpha , calcC(w_57,2) w_57_beta , calcC(w_57,3) w_57_gamma , calcC(w_57,4) w_57_delta 
, calcC(w_58,1) w_58_alpha , calcC(w_58,2) w_58_beta , calcC(w_58,3) w_58_gamma , calcC(w_58,4) w_58_delta 
, calcC(w_59,1) w_59_alpha , calcC(w_59,2) w_59_beta , calcC(w_59,3) w_59_gamma , calcC(w_59,4) w_59_delta 
, calcC(w_60,1) w_60_alpha , calcC(w_60,2) w_60_beta , calcC(w_60,3) w_60_gamma , calcC(w_60,4) w_60_delta 
, calcC(w_61,1) w_61_alpha , calcC(w_61,2) w_61_beta , calcC(w_61,3) w_61_gamma , calcC(w_61,4) w_61_delta 
, calcC(w_62,1) w_62_alpha , calcC(w_62,2) w_62_beta , calcC(w_62,3) w_62_gamma , calcC(w_62,4) w_62_delta 
, calcC(w_63,1) w_63_alpha , calcC(w_63,2) w_63_beta , calcC(w_63,3) w_63_gamma , calcC(w_63,4) w_63_delta 
, calcC(w_64,1) w_64_alpha , calcC(w_64,2) w_64_beta , calcC(w_64,3) w_64_gamma , calcC(w_64,4) w_64_delta 
, calcC(w_65,1) w_65_alpha , calcC(w_65,2) w_65_beta , calcC(w_65,3) w_65_gamma , calcC(w_65,4) w_65_delta 
, calcC(w_66,1) w_66_alpha , calcC(w_66,2) w_66_beta , calcC(w_66,3) w_66_gamma , calcC(w_66,4) w_66_delta 
, calcC(w_67,1) w_67_alpha , calcC(w_67,2) w_67_beta , calcC(w_67,3) w_67_gamma , calcC(w_67,4) w_67_delta 
, calcC(w_68,1) w_68_alpha , calcC(w_68,2) w_68_beta , calcC(w_68,3) w_68_gamma , calcC(w_68,4) w_68_delta 
, calcC(w_69,1) w_69_alpha , calcC(w_69,2) w_69_beta , calcC(w_69,3) w_69_gamma , calcC(w_69,4) w_69_delta 
, calcC(w_70,1) w_70_alpha , calcC(w_70,2) w_70_beta , calcC(w_70,3) w_70_gamma , calcC(w_70,4) w_70_delta 
, calcC(w_71,1) w_71_alpha , calcC(w_71,2) w_71_beta , calcC(w_71,3) w_71_gamma , calcC(w_71,4) w_71_delta 
, calcC(w_72,1) w_72_alpha , calcC(w_72,2) w_72_beta , calcC(w_72,3) w_72_gamma , calcC(w_72,4) w_72_delta 
, calcC(w_73,1) w_73_alpha , calcC(w_73,2) w_73_beta , calcC(w_73,3) w_73_gamma , calcC(w_73,4) w_73_delta 
, calcC(w_74,1) w_74_alpha , calcC(w_74,2) w_74_beta , calcC(w_74,3) w_74_gamma , calcC(w_74,4) w_74_delta 
, calcC(w_75,1) w_75_alpha , calcC(w_75,2) w_75_beta , calcC(w_75,3) w_75_gamma , calcC(w_75,4) w_75_delta 
, calcC(w_76,1) w_76_alpha , calcC(w_76,2) w_76_beta , calcC(w_76,3) w_76_gamma , calcC(w_76,4) w_76_delta 
, calcC(w_77,1) w_77_alpha , calcC(w_77,2) w_77_beta , calcC(w_77,3) w_77_gamma , calcC(w_77,4) w_77_delta 
, calcC(w_78,1) w_78_alpha , calcC(w_78,2) w_78_beta , calcC(w_78,3) w_78_gamma , calcC(w_78,4) w_78_delta 
, calcC(w_79,1) w_79_alpha , calcC(w_79,2) w_79_beta , calcC(w_79,3) w_79_gamma , calcC(w_79,4) w_79_delta 
, calcC(w_80,1) w_80_alpha , calcC(w_80,2) w_80_beta , calcC(w_80,3) w_80_gamma , calcC(w_80,4) w_80_delta 
, calcC(w_81,1) w_81_alpha , calcC(w_81,2) w_81_beta , calcC(w_81,3) w_81_gamma , calcC(w_81,4) w_81_delta 
, calcC(w_82,1) w_82_alpha , calcC(w_82,2) w_82_beta , calcC(w_82,3) w_82_gamma , calcC(w_82,4) w_82_delta 
, calcC(w_83,1) w_83_alpha , calcC(w_83,2) w_83_beta , calcC(w_83,3) w_83_gamma , calcC(w_83,4) w_83_delta 
, calcC(w_84,1) w_84_alpha , calcC(w_84,2) w_84_beta , calcC(w_84,3) w_84_gamma , calcC(w_84,4) w_84_delta 
, calcC(w_85,1) w_85_alpha , calcC(w_85,2) w_85_beta , calcC(w_85,3) w_85_gamma , calcC(w_85,4) w_85_delta 
, calcC(w_86,1) w_86_alpha , calcC(w_86,2) w_86_beta , calcC(w_86,3) w_86_gamma , calcC(w_86,4) w_86_delta 
, calcC(w_87,1) w_87_alpha , calcC(w_87,2) w_87_beta , calcC(w_87,3) w_87_gamma , calcC(w_87,4) w_87_delta 
, calcC(w_88,1) w_88_alpha , calcC(w_88,2) w_88_beta , calcC(w_88,3) w_88_gamma , calcC(w_88,4) w_88_delta 
, calcC(w_89,1) w_89_alpha , calcC(w_89,2) w_89_beta , calcC(w_89,3) w_89_gamma , calcC(w_89,4) w_89_delta 
, calcC(w_90,1) w_90_alpha , calcC(w_90,2) w_90_beta , calcC(w_90,3) w_90_gamma , calcC(w_90,4) w_90_delta 
, calcC(w_91,1) w_91_alpha , calcC(w_91,2) w_91_beta , calcC(w_91,3) w_91_gamma , calcC(w_91,4) w_91_delta 
, calcC(w_92,1) w_92_alpha , calcC(w_92,2) w_92_beta , calcC(w_92,3) w_92_gamma , calcC(w_92,4) w_92_delta 
, calcC(w_93,1) w_93_alpha , calcC(w_93,2) w_93_beta , calcC(w_93,3) w_93_gamma , calcC(w_93,4) w_93_delta 
, calcC(w_94,1) w_94_alpha , calcC(w_94,2) w_94_beta , calcC(w_94,3) w_94_gamma , calcC(w_94,4) w_94_delta 
, calcC(w_95,1) w_95_alpha , calcC(w_95,2) w_95_beta , calcC(w_95,3) w_95_gamma , calcC(w_95,4) w_95_delta 
, calcC(w_96,1) w_96_alpha , calcC(w_96,2) w_96_beta , calcC(w_96,3) w_96_gamma , calcC(w_96,4) w_96_delta 
, calcC(w_97,1) w_97_alpha , calcC(w_97,2) w_97_beta , calcC(w_97,3) w_97_gamma , calcC(w_97,4) w_97_delta 
, calcC(w_98,1) w_98_alpha , calcC(w_98,2) w_98_beta , calcC(w_98,3) w_98_gamma , calcC(w_98,4) w_98_delta 
, calcC(w_99,1) w_99_alpha , calcC(w_99,2) w_99_beta , calcC(w_99,3) w_99_gamma , calcC(w_99,4) w_99_delta 
, calcC(w_100,1) w_100_alpha , calcC(w_100,2) w_100_beta , calcC(w_100,3) w_100_gamma , calcC(w_100,4) w_100_delta 
, calcC(w_101,1) w_101_alpha , calcC(w_101,2) w_101_beta , calcC(w_101,3) w_101_gamma , calcC(w_101,4) w_101_delta 
, calcC(w_102,1) w_102_alpha , calcC(w_102,2) w_102_beta , calcC(w_102,3) w_102_gamma , calcC(w_102,4) w_102_delta 
, calcC(w_103,1) w_103_alpha , calcC(w_103,2) w_103_beta , calcC(w_103,3) w_103_gamma , calcC(w_103,4) w_103_delta 
, calcC(w_104,1) w_104_alpha , calcC(w_104,2) w_104_beta , calcC(w_104,3) w_104_gamma , calcC(w_104,4) w_104_delta 
, calcC(w_105,1) w_105_alpha , calcC(w_105,2) w_105_beta , calcC(w_105,3) w_105_gamma , calcC(w_105,4) w_105_delta 
, calcC(w_106,1) w_106_alpha , calcC(w_106,2) w_106_beta , calcC(w_106,3) w_106_gamma , calcC(w_106,4) w_106_delta 
, calcC(w_107,1) w_107_alpha , calcC(w_107,2) w_107_beta , calcC(w_107,3) w_107_gamma , calcC(w_107,4) w_107_delta 
, calcC(w_108,1) w_108_alpha , calcC(w_108,2) w_108_beta , calcC(w_108,3) w_108_gamma , calcC(w_108,4) w_108_delta 
, calcC(w_109,1) w_109_alpha , calcC(w_109,2) w_109_beta , calcC(w_109,3) w_109_gamma , calcC(w_109,4) w_109_delta 
, calcC(w_110,1) w_110_alpha , calcC(w_110,2) w_110_beta , calcC(w_110,3) w_110_gamma , calcC(w_110,4) w_110_delta 
, calcC(w_111,1) w_111_alpha , calcC(w_111,2) w_111_beta , calcC(w_111,3) w_111_gamma , calcC(w_111,4) w_111_delta 
, calcC(w_112,1) w_112_alpha , calcC(w_112,2) w_112_beta , calcC(w_112,3) w_112_gamma , calcC(w_112,4) w_112_delta 
, calcC(w_113,1) w_113_alpha , calcC(w_113,2) w_113_beta , calcC(w_113,3) w_113_gamma , calcC(w_113,4) w_113_delta 
, calcC(w_114,1) w_114_alpha , calcC(w_114,2) w_114_beta , calcC(w_114,3) w_114_gamma , calcC(w_114,4) w_114_delta 
, calcC(w_115,1) w_115_alpha , calcC(w_115,2) w_115_beta , calcC(w_115,3) w_115_gamma , calcC(w_115,4) w_115_delta 
, calcC(w_116,1) w_116_alpha , calcC(w_116,2) w_116_beta , calcC(w_116,3) w_116_gamma , calcC(w_116,4) w_116_delta 
, calcC(w_117,1) w_117_alpha , calcC(w_117,2) w_117_beta , calcC(w_117,3) w_117_gamma , calcC(w_117,4) w_117_delta 
, calcC(w_118,1) w_118_alpha , calcC(w_118,2) w_118_beta , calcC(w_118,3) w_118_gamma , calcC(w_118,4) w_118_delta 
, calcC(w_119,1) w_119_alpha , calcC(w_119,2) w_119_beta , calcC(w_119,3) w_119_gamma , calcC(w_119,4) w_119_delta 
, calcC(w_120,1) w_120_alpha , calcC(w_120,2) w_120_beta , calcC(w_120,3) w_120_gamma , calcC(w_120,4) w_120_delta 
, calcC(w_121,1) w_121_alpha , calcC(w_121,2) w_121_beta , calcC(w_121,3) w_121_gamma , calcC(w_121,4) w_121_delta 
, calcC(w_122,1) w_122_alpha , calcC(w_122,2) w_122_beta , calcC(w_122,3) w_122_gamma , calcC(w_122,4) w_122_delta 
, calcC(w_123,1) w_123_alpha , calcC(w_123,2) w_123_beta , calcC(w_123,3) w_123_gamma , calcC(w_123,4) w_123_delta 
, calcC(w_124,1) w_124_alpha , calcC(w_124,2) w_124_beta , calcC(w_124,3) w_124_gamma , calcC(w_124,4) w_124_delta 
, calcC(w_125,1) w_125_alpha , calcC(w_125,2) w_125_beta , calcC(w_125,3) w_125_gamma , calcC(w_125,4) w_125_delta 
, calcC(w_126,1) w_126_alpha , calcC(w_126,2) w_126_beta , calcC(w_126,3) w_126_gamma , calcC(w_126,4) w_126_delta 
, calcC(w_127,1) w_127_alpha , calcC(w_127,2) w_127_beta , calcC(w_127,3) w_127_gamma , calcC(w_127,4) w_127_delta 
, calcC(w_128,1) w_128_alpha , calcC(w_128,2) w_128_beta , calcC(w_128,3) w_128_gamma , calcC(w_128,4) w_128_delta 
, calcC(w_129,1) w_129_alpha , calcC(w_129,2) w_129_beta , calcC(w_129,3) w_129_gamma , calcC(w_129,4) w_129_delta 
, calcC(w_130,1) w_130_alpha , calcC(w_130,2) w_130_beta , calcC(w_130,3) w_130_gamma , calcC(w_130,4) w_130_delta 
, calcC(w_131,1) w_131_alpha , calcC(w_131,2) w_131_beta , calcC(w_131,3) w_131_gamma , calcC(w_131,4) w_131_delta 
, calcC(w_132,1) w_132_alpha , calcC(w_132,2) w_132_beta , calcC(w_132,3) w_132_gamma , calcC(w_132,4) w_132_delta 
, calcC(w_133,1) w_133_alpha , calcC(w_133,2) w_133_beta , calcC(w_133,3) w_133_gamma , calcC(w_133,4) w_133_delta 
, calcC(w_134,1) w_134_alpha , calcC(w_134,2) w_134_beta , calcC(w_134,3) w_134_gamma , calcC(w_134,4) w_134_delta 
, calcC(w_135,1) w_135_alpha , calcC(w_135,2) w_135_beta , calcC(w_135,3) w_135_gamma , calcC(w_135,4) w_135_delta 
, calcC(w_136,1) w_136_alpha , calcC(w_136,2) w_136_beta , calcC(w_136,3) w_136_gamma , calcC(w_136,4) w_136_delta 
, calcC(w_137,1) w_137_alpha , calcC(w_137,2) w_137_beta , calcC(w_137,3) w_137_gamma , calcC(w_137,4) w_137_delta 
, calcC(w_138,1) w_138_alpha , calcC(w_138,2) w_138_beta , calcC(w_138,3) w_138_gamma , calcC(w_138,4) w_138_delta 
, calcC(w_139,1) w_139_alpha , calcC(w_139,2) w_139_beta , calcC(w_139,3) w_139_gamma , calcC(w_139,4) w_139_delta 
, calcC(w_140,1) w_140_alpha , calcC(w_140,2) w_140_beta , calcC(w_140,3) w_140_gamma , calcC(w_140,4) w_140_delta 
, calcC(w_141,1) w_141_alpha , calcC(w_141,2) w_141_beta , calcC(w_141,3) w_141_gamma , calcC(w_141,4) w_141_delta 
, calcC(w_142,1) w_142_alpha , calcC(w_142,2) w_142_beta , calcC(w_142,3) w_142_gamma , calcC(w_142,4) w_142_delta 
, calcC(w_143,1) w_143_alpha , calcC(w_143,2) w_143_beta , calcC(w_143,3) w_143_gamma , calcC(w_143,4) w_143_delta 
, calcC(w_144,1) w_144_alpha , calcC(w_144,2) w_144_beta , calcC(w_144,3) w_144_gamma , calcC(w_144,4) w_144_delta 
, calcC(w_145,1) w_145_alpha , calcC(w_145,2) w_145_beta , calcC(w_145,3) w_145_gamma , calcC(w_145,4) w_145_delta 
, calcC(w_146,1) w_146_alpha , calcC(w_146,2) w_146_beta , calcC(w_146,3) w_146_gamma , calcC(w_146,4) w_146_delta 
, calcC(w_147,1) w_147_alpha , calcC(w_147,2) w_147_beta , calcC(w_147,3) w_147_gamma , calcC(w_147,4) w_147_delta 
, calcC(w_148,1) w_148_alpha , calcC(w_148,2) w_148_beta , calcC(w_148,3) w_148_gamma , calcC(w_148,4) w_148_delta 
, calcC(w_149,1) w_149_alpha , calcC(w_149,2) w_149_beta , calcC(w_149,3) w_149_gamma , calcC(w_149,4) w_149_delta 
FROM table_w;
