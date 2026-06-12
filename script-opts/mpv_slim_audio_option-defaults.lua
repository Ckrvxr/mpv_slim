return {
    sofa_preset = "SADIEII_D1_48K_24bit_256tap_FIR_SOFA",
    sofa_radius = 1.00,
    sofa_gain = 10,
    sofalizer = "lavfi=[sofalizer=sofa='SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa':radius=1.00:gain=10]",
    loudnorm = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=20.0]",
    loudnorm_id = "Dolby_Cinema_Classical",
    eq = '',
    eq_file = nil,
}
