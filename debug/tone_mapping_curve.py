import tkinter as tk
from tkinter import ttk
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

# ==============================================================================
# CONFIDENTIAL CODING STANDARD: ALL COMMENTS AND TEXTS IN ENGLISH
# ARCHITECTURE: 11-CURVE COMPLETE UNIVERSE WITH VISIBILITY TOGGLE PANEL
# ==============================================================================

# ==============================================================================
# ST 2084 (PQ) Transfer Function Constants
# ==============================================================================
PQ_M1 = 0.1593017578125
PQ_M2 = 78.84375
PQ_C1 = 0.8359375
PQ_C2 = 18.8515625
PQ_C3 = 18.6875


def pq_oetf(L):
    """Linear luminance [0, 10000] nits → PQ [0, 1]"""
    L_norm = L / 10000.0
    L_m1 = np.maximum(L_norm, 0.0) ** PQ_M1
    return ((PQ_C1 + PQ_C2 * L_m1) / (1.0 + PQ_C3 * L_m1)) ** PQ_M2


def pq_eotf(V):
    """PQ [0, 1] → linear luminance [0, 10000] nits"""
    V_1_m2 = np.maximum(V, 0.0) ** (1.0 / PQ_M2)
    L_norm = np.maximum(V_1_m2 - PQ_C1, 0.0) / (PQ_C2 - PQ_C3 * V_1_m2)
    L_norm = L_norm ** (1.0 / PQ_M1)
    return L_norm * 10000.0


def calculate_spline_pq(x_linear, source_peak, target_peak, knee_pq_param=0.30):
    x_pq = pq_oetf(x_linear)
    source_peak_pq = pq_oetf(source_peak)
    target_peak_pq = pq_oetf(target_peak)

    y_pq = np.copy(x_pq)

    knee_pq = min(knee_pq_param, target_peak_pq - 0.01)

    mask = x_pq > knee_pq
    if np.any(mask) and source_peak_pq > knee_pq:
        src_headroom = source_peak_pq - knee_pq
        dst_headroom = target_peak_pq - knee_pq

        delta_x = x_pq[mask] - knee_pq
        y_pq[mask] = knee_pq + dst_headroom * (1.0 - 1.0 / np.square(1.0 + delta_x / dst_headroom))

    y_linear = pq_eotf(y_pq)
    return np.minimum(y_linear, target_peak)


class HDRExhaustiveParamStudio:
    def __init__(self, root):
        self.root = root
        self.root.title("mpv HDR Tone Mapping Complete 11-Curve Param Studio")
        self.root.geometry("1400x900")
        self.root.configure(bg="#121212")

        plt.style.use('dark_background')
        
        # Main Layout splitting: Left (Canvas), Right (Controls Container)
        self.main_pane = tk.PanedWindow(self.root, orient=tk.HORIZONTAL, bg="#121212", bd=0)
        self.main_pane.pack(fill=tk.BOTH, expand=1)

        # Left Canvas Allocation
        self.fig, self.ax = plt.subplots(figsize=(10, 8), facecolor='#121212')
        self.ax.set_facecolor('#1e1e1e')
        self.canvas = FigureCanvasTkAgg(self.fig, master=self.main_pane)
        self.main_pane.add(self.canvas.get_tk_widget(), stretch="always")

        # Right Controls Panel Wrapper
        right_panel = tk.Frame(self.root, bg="#121212", width=380)
        self.main_pane.add(right_panel, stretch="never")

        # ----------------------------------------------------------------------
        # Section 1: Global Brightness Parameters
        # ----------------------------------------------------------------------
        global_frame = tk.LabelFrame(right_panel, text=" Global Luminance Context ", fg="#ffffff", bg="#121212", font=("Arial", 10, "bold"))
        global_frame.pack(fill=tk.X, padx=10, pady=5)

        self.source_var = tk.DoubleVar(value=400.0)
        self.target_var = tk.DoubleVar(value=203.0)

        self._build_slider(global_frame, 0, "Source Peak (Nits):", self.source_var, 100, 4000, 400.0)
        self._build_slider(global_frame, 1, "Target Cap (Nits):", self.target_var, 100, 1500, 203.0)

        # ----------------------------------------------------------------------
        # Section 2: --tone-mapping-param Tuning Grid
        # ----------------------------------------------------------------------
        params_frame = tk.LabelFrame(right_panel, text=" --tone-mapping-param Tuning ", fg="#ffffff", bg="#121212", font=("Arial", 10, "bold"))
        params_frame.pack(fill=tk.X, padx=10, pady=5)

        self.params = {
            'clip': tk.DoubleVar(value=1.0),
            'linear': tk.DoubleVar(value=1.0),
            'gamma': tk.DoubleVar(value=1.8),
            'reinhard': tk.DoubleVar(value=0.5),
            'mobius': tk.DoubleVar(value=0.3),
            'spline': tk.DoubleVar(value=0.30),
            'bt2390': tk.DoubleVar(value=1.0),
            'st2094_10': tk.DoubleVar(value=1.0)
        }

        self._build_slider(params_frame, 0, "Clip Multiplier:", self.params['clip'], 0.1, 3.0, 1.0)
        self._build_slider(params_frame, 1, "Linear Scale:", self.params['linear'], 0.1, 3.0, 1.0)
        self._build_slider(params_frame, 2, "Gamma Exponent:", self.params['gamma'], 0.5, 3.0, 1.8)
        self._build_slider(params_frame, 3, "Reinhard Contrast:", self.params['reinhard'], 0.1, 0.99, 0.5)
        self._build_slider(params_frame, 4, "Mobius Knee Point:", self.params['mobius'], 0.05, 0.9, 0.3)
        self._build_slider(params_frame, 5, "Spline Knee PQ:", self.params['spline'], 0.05, 0.95, 0.30)
        self._build_slider(params_frame, 6, "BT.2390 Knee Offset:", self.params['bt2390'], 0.1, 2.0, 1.0)
        self._build_slider(params_frame, 7, "ST2094-10 Slope:", self.params['st2094_10'], 0.1, 3.0, 1.0)

        # ----------------------------------------------------------------------
        # Section 3: 11-Curve Checklist Layer Visibility Toggle
        # ----------------------------------------------------------------------
        visibility_frame = tk.LabelFrame(right_panel, text=" Render Layer Visibility Toggles ", fg="#ffffff", bg="#121212", font=("Arial", 10, "bold"))
        visibility_frame.pack(fill=tk.BOTH, expand=1, padx=10, pady=5)

        # Master mapping definitions for all 11 curves shown in mpv OSD options array
        self.curve_definitions = {
            'Clip': ('#ff4500', '-'),
            'Linear': ('#ff8c00', ':'),
            'Gamma': ('#8a2be2', '-'),
            'Reinhard': ('#ff69b4', '-'),
            'Hable': ('#ff1493', '-.'),
            'Mobius': ('#00ced1', '-'),
            'Spline': ('#32cd32', '-'),
            'BT.2390': ('#1e90ff', '-'),
            'BT.2446a': ('#ffd700', '-'),
            'ST2094-10': ('#e91e63', '-'),
            'ST2094-40': ('#00efff', '-')
        }

        self.visibility_vars = {}
        # Pack checkbuttons inside a clean scannable column layout
        for i, name in enumerate(self.curve_definitions.keys()):
            # Default active set curated to prevent initial plotting overflow
            default_state = name in ['Clip', 'Reinhard','Hable', 'Mobius', 'Spline', 'BT.2390', 'BT.2446a', 'ST2094-40']
            self.visibility_vars[name] = tk.BooleanVar(value=default_state)
            
            cb = tk.Checkbutton(visibility_frame, text=f"Show {name}", variable=self.visibility_vars[name],
                                 fg=self.curve_definitions[name][0], bg="#121212", selectcolor="#222222",
                                 activebackground="#121212", activeforeground="#ffffff",
                                 command=self.update_plot, font=("Arial", 9, "bold"))
            cb.pack(anchor="w", padx=15, pady=2)

        self.update_plot()

    def _build_slider(self, parent, row, label_text, variable, min_val, max_val, default_val):
        tk.Label(parent, text=label_text, fg="#aaaaaa", bg="#121212", width=18, anchor="w").grid(row=row, column=0, sticky="w", padx=5, pady=1)
        slider = ttk.Scale(parent, from_=min_val, to=max_val, orient=tk.HORIZONTAL, length=150, variable=variable, command=self.update_plot)
        slider.grid(row=row, column=1, padx=5)
        
        value_label = tk.Label(parent, text=f"{default_val:.2f}", fg="#ffffff", bg="#121212", width=5)
        value_label.grid(row=row, column=2, padx=5)
        
        def update_label(*args):
            value_label.config(text=f"{variable.get():.2f}")
        variable.trace_add("write", update_label)

    def update_plot(self, event=None):
        source_peak = max(1.0, self.source_var.get())
        target_peak = max(1.0, self.target_var.get())

        self.ax.clear()
        x = np.linspace(0.0, source_peak, 2000)

        # Baseline Reference Line
        self.ax.plot(x, x, '--', color='#444444', label='1:1 Reference')

        # ----------------------------------------------------------------------
        # Mathematical Formulations for All 11 Modes
        # ----------------------------------------------------------------------
        curves_data = {}

        # 1. Clip
        curves_data['Clip'] = np.minimum(x * self.params['clip'].get(), target_peak)
        
        # 2. Linear
        curves_data['Linear'] = np.minimum(x * self.params['linear'].get(), target_peak)
        
        # 3. Gamma
        curves_data['Gamma'] = np.minimum(target_peak * (x / source_peak) ** (1.0 / self.params['gamma'].get()), target_peak)
        
        # 4. Reinhard
        p_rein = self.params['reinhard'].get()
        c_rein = (1.0 - p_rein) / (p_rein * target_peak)
        curves_data['Reinhard'] = np.minimum(x / (1.0 + c_rein * x), target_peak)
        
        # 5. Hable (John Hable's Sigmoidal Filmic formulation proxy)
        # Matches manual's directive: slightly sigmoidal, desaturates highlights safely
        curves_data['Hable'] = np.minimum(target_peak * (x**2 / (x**2 + (target_peak * 0.4)**2)), target_peak)

        # 6. Mobius
        p_mob = self.params['mobius'].get()
        k_mob = target_peak * p_mob
        c_mob = target_peak - k_mob
        y_mob = np.copy(x)
        y_mob[x > k_mob] = k_mob + c_mob * (x[x > k_mob] - k_mob) / (x[x > k_mob] - k_mob + c_mob)
        curves_data['Mobius'] = np.minimum(y_mob, target_peak)

        # 7. Spline (mpv/libplacebo native rational spline)
        knee_pq = self.params['spline'].get()
        curves_data['Spline'] = calculate_spline_pq(x, source_peak, target_peak, knee_pq)

        # 8. BT.2390
        p_bt = self.params['bt2390'].get()
        k_bt = target_peak * (0.55 * p_bt)
        c_bt = target_peak - k_bt
        y_bt = np.copy(x)
        if c_bt > 0:
            y_bt[x > k_bt] = k_bt + c_bt * (1.0 - np.exp(-(x[x > k_bt] - k_bt) / c_bt))
        curves_data['BT.2390'] = np.minimum(y_bt, target_peak)

        # 9. BT.2446a
        k_2446 = target_peak * 0.20
        c_2446 = target_peak - k_2446
        y_2446 = np.copy(x)
        y_2446[x > k_2446] = k_2446 + c_2446 * (1.0 - 1.0 / (1.0 + (x[x > k_2446] - k_2446) / (2.0 * c_2446))**2)
        curves_data['BT.2446a'] = np.minimum(y_2446, target_peak)

        # 10. ST2094-10
        p_st10 = self.params['st2094_10'].get()
        k_st10 = target_peak * 0.50
        c_st10 = target_peak - k_st10
        y_st10 = np.copy(x)
        if c_st10 > 0:
            y_st10[x > k_st10] = k_st10 + c_st10 * (1.0 - np.exp(-p_st10 * (x[x > k_st10] - k_st10) / c_st10))
        curves_data['ST2094-10'] = np.minimum(y_st10, target_peak)

        # 11. ST2094-40 (Dynamic HDR10+ Adaptive Spline curve approximation)
        k_st40 = target_peak * 0.38
        c_st40 = target_peak - k_st40
        y_st40 = np.copy(x)
        # Emulates high-order polynomial matching the frame average brightness context
        y_st40[x > k_st40] = k_st40 + c_st40 * (1.0 - 1.0 / (1.0 + (x[x > k_st40] - k_st40) / (1.5 * c_st40))**1.5)
        curves_data['ST2094-40'] = np.minimum(y_st40, target_peak)

        # ----------------------------------------------------------------------
        # Selective Render Execution Loop
        # ----------------------------------------------------------------------
        for name, (color, style) in self.curve_definitions.items():
            if self.visibility_vars[name].get():
                self.ax.plot(x, curves_data[name], linestyle=style, color=color, linewidth=2, label=name)

        # Hardware boundary line indicators
        self.ax.axhline(y=target_peak, color='#ff6b6b', linestyle='-.', alpha=0.5)
        self.ax.text(source_peak * 0.02, target_peak + (target_peak * 0.015), f'Display Target: {int(target_peak)} Nits', color='#ff6b6b', fontsize=10)

        # Canvas cosmetics mapping
        self.ax.set_title('mpv Complete 11-Curve Exhaustive Calibration Studio', color='#ffffff', fontsize=12, pad=10)
        self.ax.set_xlabel('Input Content Luminance (Nits)', color='#ffffff', labelpad=5)
        self.ax.set_ylabel('Output Projected Display Luminance (Nits)', color='#ffffff', labelpad=5)
        
        self.ax.set_xlim(0, source_peak)
        self.ax.set_ylim(0, target_peak * 1.15)
        self.ax.grid(True, color='#333333', linestyle='--', alpha=0.5)
        self.ax.legend(loc='lower right', facecolor='#2d2d2d', edgecolor='#444444', fontsize=9, ncol=2)

        self.canvas.draw()

if __name__ == "__main__":
    root = tk.Tk()
    style = ttk.Style()
    style.theme_use('default')
    style.configure("TScale", background="#121212", troughcolor="#333333")
    
    app = HDRExhaustiveParamStudio(root)
    root.mainloop()