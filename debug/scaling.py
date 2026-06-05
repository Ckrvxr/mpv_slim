import tkinter as tk
from tkinter import ttk
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

# ==============================================================================
# CONFIDENTIAL CODING STANDARD: ALL COMMENTS AND TEXTS IN ENGLISH
# ARCHITECTURE: MULTI-FILTER VISUALIZATION STUDIO (LIGHT THEME)
# ==============================================================================

# ==============================================================================
# Filter Kernel Implementations
# ==============================================================================

def mitchell_netravali(x, B, C):
    """Mitchell-Netravali cubic filter kernel with parameters B (blur) and C (ringing)."""
    x = np.abs(x)
    if x < 1:
        return ((12 - 9*B - 6*C) * x**3 + 
                (-18 + 12*B + 6*C) * x**2 + 
                (6 - 2*B)) / 6.0  # Normalized (divided by 6)
    elif x < 2:
        return ((-B - 6*C) * x**3 + 
                (6*B + 30*C) * x**2 + 
                (-12*B - 48*C) * x + 
                (8*B + 24*C)) / 6.0
    else:
        return 0.0

def nearest_neighbor(x):
    """Nearest neighbor (Box) filter."""
    return 1.0 if np.abs(x) < 0.5 else 0.0

def linear_filter(x):
    """Linear (Triangle/Bilinear) filter."""
    x = np.abs(x)
    return max(0.0, 1.0 - x)

def lanczos(x, a=2):
    """Lanczos filter with radius 'a'."""
    x = np.abs(x)
    if x == 0:
        return 1.0
    elif x < a:
        # np.sinc in numpy is already normalized: sin(pi*x)/(pi*x)
        return np.sinc(x) * np.sinc(x / a)
    else:
        return 0.0

def sinc_filter(x):
    """Ideal sinc (sin(πx)/(πx)) reconstruction filter."""
    return np.sinc(x)

def lanczos_sharp(x, a):
    """Lanczos with sqrt window for sharper result."""
    x = np.abs(x)
    if x == 0:
        return 1.0
    elif x < a:
        return np.sinc(x) * np.sinc(x / a) ** 0.5
    else:
        return 0.0

def spline16(x):
    x = abs(x)
    if x < 1:
        return ((x - 9/5) * x - 1/5) * x + 1
    elif x < 2:
        u = x - 1
        return ((-1/3 * u + 4/5) * u - 7/15) * u
    return 0.0

def spline36(x):
    x = abs(x)
    if x < 1:
        return ((13/11 * x - 453/209) * x - 3/209) * x + 1
    elif x < 2:
        u = x - 1
        return ((-6/11 * u + 270/209) * u - 156/209) * u
    elif x < 3:
        u = x - 2
        return ((1/11 * u - 45/209) * u + 26/209) * u
    return 0.0

def spline64(x):
    x = abs(x)
    if x < 1:
        return ((49/41 * x - 6387/2911) * x - 3/2911) * x + 1
    elif x < 2:
        u = x - 1
        return ((-24/41 * u + 4032/2911) * u - 2328/2911) * u
    elif x < 3:
        u = x - 2
        return ((6/41 * u - 1008/2911) * u + 582/2911) * u
    elif x < 4:
        u = x - 3
        return ((-1/41 * u + 168/2911) * u - 97/2911) * u
    return 0.0


class FilterFamilyStudio:
    def __init__(self, root):
        self.root = root
        self.root.title("Filter Family Complete Visualization Studio")
        self.root.geometry("1600x1000")
        
        # 🎨 Light Theme Colors
        self.bg_color = "#F5F6FA"        # Main background
        self.panel_bg = "#FFFFFF"        # Panel background
        self.fg_color = "#2F3640"        # Text color
        self.sub_text = "#718093"        # Subtitle/dimmed text
        self.plot_bg = "#FFFFFF"         # Plot area background
        self.grid_color = "#DCDDE1"      # Grid line color
        self.highlight = "#0097E6"       # Current selection color

        self.root.configure(bg=self.bg_color)
        
        # Main Layout: Left (Canvas Area), Right (Controls Panel)
        self.main_pane = tk.PanedWindow(self.root, orient=tk.HORIZONTAL, bg=self.bg_color, bd=0)
        self.main_pane.pack(fill=tk.BOTH, expand=1)

        # Left Canvas Area
        left_frame = tk.Frame(self.root, bg=self.bg_color)
        self.main_pane.add(left_frame, stretch="always")

        self.fig, (self.ax_kernel, self.ax_gray) = plt.subplots(
            2, 1, figsize=(10, 10), facecolor=self.bg_color,
            gridspec_kw={'height_ratios': [1, 1]}
        )
        self.ax_kernel.set_facecolor(self.plot_bg)
        self.ax_gray.set_facecolor(self.plot_bg)
        
        self.canvas = FigureCanvasTkAgg(self.fig, master=left_frame)
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=1)

        # Right Controls Panel
        right_panel = tk.Frame(self.root, bg=self.panel_bg, width=420, highlightbackground=self.grid_color, highlightthickness=1)
        self.main_pane.add(right_panel, stretch="never")

        # ==============================================================================
        # Section 1: MN B-C Parameter Tuning Grid
        # ==============================================================================
        params_frame = tk.LabelFrame(
            right_panel, text=" Mitchell-Netravali (B-C) Tuning ",
            fg=self.fg_color, bg=self.panel_bg, font=("Arial", 10, "bold")
        )
        params_frame.pack(fill=tk.X, padx=10, pady=10)

        self.b_var = tk.DoubleVar(value=1/3)
        self.c_var = tk.DoubleVar(value=1/3)
        
        self._build_slider_pack(params_frame, "Blur (B):", self.b_var, 0.0, 2.0, 1/3)
        self._build_slider_pack(params_frame, "Ringing (C):", self.c_var, -0.5, 1.5, 1/3)

        # ==============================================================================
        # Section 2: MN Preset Filters
        # ==============================================================================
        preset_frame = tk.LabelFrame(
            right_panel, text=" Cubic Filter Presets ",
            fg=self.fg_color, bg=self.panel_bg, font=("Arial", 10, "bold")
        )
        preset_frame.pack(fill=tk.X, padx=10, pady=5)

        self.preset_filters = {
            'B-Spline': (1.0, 0.0),
            'Mitchell-Netravali': (1/3, 1/3),
            'Catmull-Rom': (0.0, 0.5),
            'Sharp Bicubic': (0.0, 1.0),
            'Hermite': (0.0, 0.0),
        }

        self.preset_var = tk.StringVar(value='Mitchell-Netravali')
        preset_menu = ttk.Combobox(
            preset_frame, textvariable=self.preset_var,
            values=list(self.preset_filters.keys()),
            state="readonly", width=25
        )
        preset_menu.pack(fill=tk.X, padx=10, pady=5)
        preset_menu.bind("<<ComboboxSelected>>", self.on_preset_change)

        # ==============================================================================
        # Section 3: Visibility Toggles (MN & Common Filters)
        # ==============================================================================
        visibility_frame = tk.LabelFrame(
            right_panel, text=" Render Layer Visibility Toggles ",
            fg=self.fg_color, bg=self.panel_bg, font=("Arial", 10, "bold")
        )
        visibility_frame.pack(fill=tk.BOTH, expand=1, padx=10, pady=5)

        # 🧮 Dictionary of all extra common filters: (Color, LineStyle, Function, Radius)
        self.common_filters = {
            'Nearest Neighbor': ('#E15F99', ':', lambda x: nearest_neighbor(x), 0.5),
            'Linear (Triangle)': ('#F2994A', '-.', lambda x: linear_filter(x), 1.0),
            'Lanczos-2': ('#27AE60', '--', lambda x: lanczos(x, 2), 2.0),
            'Lanczos-3': ('#8E44AD', '--', lambda x: lanczos(x, 3), 3.0),
            'Sinc': ('#00BFFF', '-', lambda x: sinc_filter(x), 4.0),
            'ewa_lanczossharp': ('#FF8C00', '-', lambda x: lanczos_sharp(x, 3), 3.0),
            'ewa_lanczos4sharpest': ('#FF0055', '-', lambda x: lanczos_sharp(x, 4), 4.0),
            'Spline16': ('#DAA520', '-', lambda x: spline16(x), 2.0),
            'Spline36': ('#9370DB', '-', lambda x: spline36(x), 3.0),
            'Spline64': ('#20B2AA', '-', lambda x: spline64(x), 4.0),
        }

        # MN cubic filter styles
        self.mn_styles = {
            'B-Spline': ('#3498DB', '-'),
            'Mitchell-Netravali': ('#E74C3C', '-'),
            'Catmull-Rom': ('#F39C12', '-'),
            'Sharp Bicubic': ('#D35400', '-'),
            'Hermite': ('#16A085', '-'),
        }

        self.visibility_vars = {}

        group_cubic = ['B-Spline', 'Mitchell-Netravali', 'Catmull-Rom', 'Sharp Bicubic', 'Hermite']
        group_point = ['Nearest Neighbor', 'Linear (Triangle)']
        group_lanczos = ['Lanczos-2', 'Lanczos-3', 'ewa_lanczossharp', 'ewa_lanczos4sharpest']
        group_sinc = ['Sinc', 'Spline16', 'Spline36', 'Spline64']
        default_common = ['Linear (Triangle)', 'ewa_lanczossharp', 'ewa_lanczos4sharpest', 'Spline16', 'Spline36', 'Spline64']

        tk.Label(visibility_frame, text="-- Point & Linear --", bg=self.panel_bg, fg=self.sub_text, font=("Arial", 9, "italic")).pack(anchor="w", padx=5)
        for name in group_point:
            self._create_toggle(visibility_frame, name, self.common_filters[name][0], default=(name in default_common))

        tk.Label(visibility_frame, text="-- Cubic Filters --", bg=self.panel_bg, fg=self.sub_text, font=("Arial", 9, "italic")).pack(anchor="w", padx=5, pady=(10, 0))
        for name in group_cubic:
            self._create_toggle(visibility_frame, name, self.mn_styles[name][0], default=(name in ['Mitchell-Netravali', 'Catmull-Rom']))

        tk.Label(visibility_frame, text="-- Lanczos Family --", bg=self.panel_bg, fg=self.sub_text, font=("Arial", 9, "italic")).pack(anchor="w", padx=5, pady=(10, 0))
        for name in group_lanczos:
            self._create_toggle(visibility_frame, name, self.common_filters[name][0], default=(name in default_common))

        tk.Label(visibility_frame, text="-- Sinc & Spline --", bg=self.panel_bg, fg=self.sub_text, font=("Arial", 9, "italic")).pack(anchor="w", padx=5, pady=(10, 0))
        for name in group_sinc:
            self._create_toggle(visibility_frame, name, self.common_filters[name][0], default=(name in default_common))

        # ==============================================================================
        # Section 4: Grayscale Test Pattern Controls
        # ==============================================================================
        gray_frame = tk.LabelFrame(
            right_panel, text=" Grayscale Reconstruction Test ",
            fg=self.fg_color, bg=self.panel_bg, font=("Arial", 10, "bold")
        )
        gray_frame.pack(fill=tk.X, padx=10, pady=10)

        self.gray_pattern_var = tk.StringVar(value='Step Edge')
        pattern_menu = ttk.Combobox(
            gray_frame, textvariable=self.gray_pattern_var,
            values=['Step Edge', 'Impulse', 'Sine Wave', 'Square Wave', 'Ramp'],
            state="readonly", width=20
        )
        pattern_menu.pack(fill=tk.X, padx=10, pady=5)
        pattern_menu.bind("<<ComboboxSelected>>", self.update_plot)

        self.scale_factor = 144.0
        self.antiring_var = tk.DoubleVar(value=0.0)
        self._build_slider_pack(gray_frame, "Antiring:", self.antiring_var, 0.0, 1.0, 0.0)

        # Bind parameter changes
        self.b_var.trace_add("write", self.update_plot)
        self.c_var.trace_add("write", self.update_plot)
        self.antiring_var.trace_add("write", self.update_plot)

        self.update_plot()

    def _create_toggle(self, parent, name, color, default):
        """Helper to create checkbuttons with consistent light theme styling."""
        self.visibility_vars[name] = tk.BooleanVar(value=default)
        cb = tk.Checkbutton(
            parent, text=f"Show {name}",
            variable=self.visibility_vars[name],
            fg=color, bg=self.panel_bg, selectcolor=self.bg_color,
            activebackground=self.panel_bg, activeforeground=color,
            command=self.update_plot, font=("Arial", 9, "bold")
        )
        cb.pack(anchor="w", padx=15, pady=1)

    def _build_slider_pack(self, parent, label_text, variable, min_val, max_val, default_val):
        """Build a slider row using pack layout."""
        row_frame = tk.Frame(parent, bg=self.panel_bg)
        row_frame.pack(fill=tk.X, padx=5, pady=2)
        
        tk.Label(row_frame, text=label_text, fg=self.fg_color, bg=self.panel_bg,
                 width=12, anchor="w").pack(side=tk.LEFT)
        
        slider = ttk.Scale(row_frame, from_=min_val, to=max_val, orient=tk.HORIZONTAL,
                           length=150, variable=variable)
        slider.pack(side=tk.LEFT, padx=5)
        
        value_label = tk.Label(row_frame, text=f"{default_val:.3f}",
                               fg=self.highlight, bg=self.panel_bg, width=8, font=("Arial", 9, "bold"))
        value_label.pack(side=tk.LEFT)
        
        def update_label(*args):
            value_label.config(text=f"{variable.get():.3f}")
        variable.trace_add("write", update_label)

    def on_preset_change(self, event=None):
        preset_name = self.preset_var.get()
        if preset_name in self.preset_filters:
            B, C = self.preset_filters[preset_name]
            self.b_var.set(B)
            self.c_var.set(C)
            self.update_plot()

    # 🛠️ Updated to support arbitrary filter kernels and dynamic radiuses
    def reconstruct_grayscale(self, input_pattern, scale_factor, kernel_func, radius, x_range=None):
        input_len = len(input_pattern)
        input_center = input_len / 2

        if x_range is None:
            i_start = 0
            i_end = int(input_len * scale_factor)
        else:
            x_min, x_max = x_range
            i_start = max(0, int(np.floor((x_min + input_center) * scale_factor)))
            i_end = min(int(input_len * scale_factor), int(np.ceil((x_max + input_center) * scale_factor)))

        output_len = i_end - i_start
        output = np.zeros(output_len)
        in_mins = np.zeros(output_len)
        in_maxs = np.zeros(output_len)

        for idx, i in enumerate(range(i_start, i_end)):
            src_x = i / scale_factor
            start = max(0, int(np.floor(src_x - radius)))
            end = min(input_len, int(np.ceil(src_x + radius)) + 1)
            in_mins[idx] = input_pattern[start:end].min()
            in_maxs[idx] = input_pattern[start:end].max()
            for j in range(start, end):
                dist = src_x - j
                weight = kernel_func(dist)
                output[idx] += input_pattern[j] * weight

        return output, i_start, in_mins, in_maxs

    def apply_antiring(self, recon, in_mins, in_maxs, strength):
        if strength <= 0:
            return recon
        clamped = np.clip(recon, in_mins, in_maxs)
        return (1 - strength) * recon + strength * clamped

    def generate_test_pattern(self, pattern_type, length=4096):
        """Generate various grayscale test patterns."""
        x = np.linspace(0, 1, length)
        if pattern_type == 'Step Edge': return np.where(x < 0.5, 0.0, 1.0)
        elif pattern_type == 'Impulse': 
            p = np.zeros(length); p[length // 2] = 1.0; return p
        elif pattern_type == 'Sine Wave': return 0.5 + 0.5 * np.sin(2 * np.pi * x * 8)
        elif pattern_type == 'Square Wave': return np.where(np.sin(2 * np.pi * x * 4) > 0, 1.0, 0.0)
        elif pattern_type == 'Ramp': return x
        else: return np.zeros(length)

    def update_plot(self, *args):
        B = self.b_var.get()
        C = self.c_var.get()
        scale_factor = self.scale_factor
        pattern_type = self.gray_pattern_var.get()

        # ======================================================================
        # TOP PLOT: Kernel Function Visualization
        # ======================================================================
        self.ax_kernel.clear()
        x_kernel = np.linspace(-3.5, 3.5, 2000)
        
        # Grid and axes
        self.ax_kernel.axhline(y=0, color=self.sub_text, linestyle='--', alpha=0.3, linewidth=1)
        self.ax_kernel.axvline(x=0, color=self.sub_text, linestyle='--', alpha=0.3, linewidth=1)
        for vx in [-3, -2, -1, 1, 2, 3]:
            self.ax_kernel.axvline(x=vx, color=self.grid_color, linestyle=':', alpha=0.8, linewidth=1)
        
        self.ax_kernel.axhspan(0, -0.5, alpha=0.05, color='red', label='Ringing Zone (Negative Weight)')

        # Plot MN presets
        for name, (color, style) in self.mn_styles.items():
            if self.visibility_vars[name].get():
                B_f, C_f = self.preset_filters[name]
                y = np.array([mitchell_netravali(xi, B_f, C_f) for xi in x_kernel])
                lw = 3.0 if (name == self.preset_var.get()) else 2.0
                alpha = 1.0 if (name == self.preset_var.get()) else 0.7
                self.ax_kernel.plot(x_kernel, y, linestyle=style, color=color,
                                    linewidth=lw, alpha=alpha, label=f"{name}")

        # Plot Common Filters
        for name, (color, style, func, radius) in self.common_filters.items():
            if self.visibility_vars[name].get():
                y = np.array([func(xi) for xi in x_kernel])
                self.ax_kernel.plot(x_kernel, y, linestyle=style, color=color,
                                    linewidth=2.0, alpha=0.85, label=f"{name}")

        # Plot Current MN Active Params
        current_y = np.array([mitchell_netravali(xi, B, C) for xi in x_kernel])
        self.ax_kernel.plot(x_kernel, current_y, color=self.fg_color, linewidth=2.5,
                            linestyle='-', alpha=0.9, label=f'Current MN (B={B:.2f}, C={C:.2f})')

        self.ax_kernel.set_title(
            'Filter Kernel Family Spatial Visualization',
            color=self.fg_color, fontsize=12, fontweight='bold', pad=10
        )
        self.ax_kernel.set_xlabel('x (Pixel Distance)', color=self.fg_color, labelpad=5)
        self.ax_kernel.set_ylabel('f(x) (Weight)', color=self.fg_color, labelpad=5)
        self.ax_kernel.set_xlim(-3.5, 3.5)
        self.ax_kernel.set_ylim(-0.25, 1.1)
        self.ax_kernel.grid(True, color=self.grid_color, linestyle='-', alpha=0.5)
        
        self.ax_kernel.tick_params(colors=self.fg_color)
        self.ax_kernel.legend(loc='upper right', facecolor=self.panel_bg,
                              edgecolor=self.grid_color, fontsize=8, ncol=2)

        # ======================================================================
        # BOTTOM PLOT: Grayscale Reconstruction Test
        # ======================================================================
        self.ax_gray.clear()
        pattern = self.generate_test_pattern(pattern_type, length=4096)
        input_center = len(pattern) / 2

        antiring = self.antiring_var.get()

        if pattern_type in ('Step Edge', 'Impulse'):
            x_visible = (-3.5, 3.5)
            x_pat = np.arange(len(pattern)) - input_center
            pat_mask = (x_pat >= x_visible[0]) & (x_pat <= x_visible[1])
            self.ax_gray.plot(x_pat[pat_mask], pattern[pat_mask], color=self.sub_text, linewidth=1.5,
                              linestyle=':', alpha=0.8, label='Original')
            for name, (color, style) in self.mn_styles.items():
                if self.visibility_vars[name].get():
                    B_f, C_f = self.preset_filters[name]
                    recon, i0, in_mins, in_maxs = self.reconstruct_grayscale(pattern, scale_factor, lambda x: mitchell_netravali(x, B_f, C_f), radius=2, x_range=x_visible)
                    recon = self.apply_antiring(recon, in_mins, in_maxs, antiring)
                    x_recon = (np.arange(len(recon)) + i0) / scale_factor - input_center
                    lw = 2.5 if (name == self.preset_var.get()) else 1.5
                    alpha = 1.0 if (name == self.preset_var.get()) else 0.7
                    self.ax_gray.plot(x_recon, recon, linestyle=style, color=color, linewidth=lw, alpha=alpha, label=name)
            for name, (color, style, func, radius) in self.common_filters.items():
                 if self.visibility_vars[name].get():
                     recon, i0, in_mins, in_maxs = self.reconstruct_grayscale(pattern, scale_factor, func, radius, x_range=x_visible)
                     recon = self.apply_antiring(recon, in_mins, in_maxs, antiring)
                     x_recon = (np.arange(len(recon)) + i0) / scale_factor - input_center
                     self.ax_gray.plot(x_recon, recon, linestyle=style, color=color, linewidth=1.5, alpha=0.85, label=name)
            current_recon, i0, in_mins, in_maxs = self.reconstruct_grayscale(pattern, scale_factor, lambda x: mitchell_netravali(x, B, C), radius=2, x_range=x_visible)
            current_recon = self.apply_antiring(current_recon, in_mins, in_maxs, antiring)
            x_recon = (np.arange(len(current_recon)) + i0) / scale_factor - input_center
            self.ax_gray.plot(x_recon, current_recon, color=self.fg_color, linewidth=2.0, linestyle='-', alpha=0.9, label='Current MN')
            self.ax_gray.set_xlabel('Pixel Offset from Edge', color=self.fg_color, labelpad=5)
            self.ax_gray.set_xlim(-3.5, 3.5)
        else:
            x_pat = np.linspace(0, 1, len(pattern))
            self.ax_gray.plot(x_pat, pattern, color=self.sub_text, linewidth=1.5,
                              linestyle=':', alpha=0.8, label='Original')
            for name, (color, style) in self.mn_styles.items():
                if self.visibility_vars[name].get():
                    B_f, C_f = self.preset_filters[name]
                    recon, _, in_mins, in_maxs = self.reconstruct_grayscale(pattern, scale_factor, lambda x: mitchell_netravali(x, B_f, C_f), radius=2, x_range=None)
                    recon = self.apply_antiring(recon, in_mins, in_maxs, antiring)
                    x_recon = np.linspace(0, 1, len(recon))
                    lw = 2.5 if (name == self.preset_var.get()) else 1.5
                    alpha = 1.0 if (name == self.preset_var.get()) else 0.7
                    self.ax_gray.plot(x_recon, recon, linestyle=style, color=color, linewidth=lw, alpha=alpha, label=name)
            for name, (color, style, func, radius) in self.common_filters.items():
                 if self.visibility_vars[name].get():
                     recon, _, in_mins, in_maxs = self.reconstruct_grayscale(pattern, scale_factor, func, radius, x_range=None)
                     recon = self.apply_antiring(recon, in_mins, in_maxs, antiring)
                     x_recon = np.linspace(0, 1, len(recon))
                     self.ax_gray.plot(x_recon, recon, linestyle=style, color=color, linewidth=1.5, alpha=0.85, label=name)
            current_recon, _, in_mins, in_maxs = self.reconstruct_grayscale(pattern, scale_factor, lambda x: mitchell_netravali(x, B, C), radius=2, x_range=None)
            current_recon = self.apply_antiring(current_recon, in_mins, in_maxs, antiring)
            x_recon = np.linspace(0, 1, len(current_recon))
            self.ax_gray.plot(x_recon, current_recon, color=self.fg_color, linewidth=2.0, linestyle='-', alpha=0.9, label='Current MN')
            self.ax_gray.set_xlabel('Normalized Position', color=self.fg_color, labelpad=5)
            x_lim = (0.3, 0.7) if pattern_type in ('Sine Wave', 'Square Wave') else (0, 1)
            self.ax_gray.set_xlim(*x_lim)

        self.ax_gray.set_title(
            f'1D Grayscale Reconstruction Test ({pattern_type} @ {scale_factor}x)',
            color=self.fg_color, fontsize=12, fontweight='bold', pad=10
        )
        self.ax_gray.set_ylabel('Luminance', color=self.fg_color, labelpad=5)
        self.ax_gray.set_ylim(-0.2, 1.2)
        self.ax_gray.grid(True, color=self.grid_color, linestyle='-', alpha=0.5)
        self.ax_gray.tick_params(colors=self.fg_color)
        self.ax_gray.legend(loc='upper right', facecolor=self.panel_bg,
                            edgecolor=self.grid_color, fontsize=8, ncol=3)

        self.ax_gray.axhline(y=0, color=self.sub_text, linestyle='--', alpha=0.3, linewidth=1)
        self.ax_gray.axhline(y=1, color=self.sub_text, linestyle='--', alpha=0.3, linewidth=1)
        
        self.ax_gray.axhspan(1.0, 1.2, alpha=0.05, color='red')
        self.ax_gray.axhspan(-0.2, 0.0, alpha=0.05, color='red')

        self.fig.tight_layout()
        self.canvas.draw()


if __name__ == "__main__":
    root = tk.Tk()
    style = ttk.Style()
    style.theme_use('default')
    
    # Configure ttk components for Light Theme
    style.configure("TScale", background="#FFFFFF", troughcolor="#DCDDE1")
    style.configure("TCombobox", fieldbackground="#FFFFFF", background="#FFFFFF")
    
    app = FilterFamilyStudio(root)
    root.mainloop()