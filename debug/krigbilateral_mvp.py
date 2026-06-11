import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import zoom

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False

np.random.seed(1024)  # 保持相同的噪声种子

# ============ 1. 生成极端测试图案（高对比度边缘 + 强噪） ============
size = 256  
x = np.linspace(-1, 1, size)
y = np.linspace(-1, 1, size)
X, Y = np.meshgrid(x, y)

# 基础无噪信号
gt_signal = np.zeros((size, size))
# 1. 棋盘格背景
checker = (np.floor(X * 4) % 2 == np.floor(Y * 4) % 2).astype(float)
gt_signal[checker == 1] = 0.7
gt_signal[checker == 0] = 0.2

# 2. 中心强白圆
R = np.sqrt(X**2 + Y**2)
gt_signal[R < 0.35] = 1.0
# 3. 中心内部的一个深色方块
gt_signal[(R < 0.15) & (X > 0)] = 0.0

# 添加显著的随机高斯噪声
test_img = np.clip(gt_signal + np.random.normal(0, 0.12, (size, size)), 0, 1)

# 下采样 2 倍 -> 128x128
low_img = test_img[::2, ::2]

# ============ 2. 算法实现 ============

def catmull_rom_1d(y, x_new):
    """一维 Catmull-Rom (Hermite) 插值"""
    n = len(y)
    tangents = np.zeros(n)
    tangents[1:-1] = (y[2:] - y[:-2]) / 2
    tangents[0] = y[1] - y[0]
    tangents[-1] = y[-1] - y[-2]
    
    result = np.zeros(len(x_new))
    for i in range(len(x_new)):
        xi = x_new[i]
        if xi <= 0:
            result[i] = y[0]
        elif xi >= n - 1:
            result[i] = y[-1]
        else:
            idx = int(np.floor(xi))
            t = xi - idx
            
            p0, p1 = y[idx], y[idx + 1]
            m0, m1 = tangents[idx], tangents[idx + 1]
            
            h00 = 2*t**3 - 3*t**2 + 1
            h10 = t**3 - 2*t**2 + t
            h01 = -2*t**3 + 3*t**2
            h11 = t**3 - t**2
            
            result[i] = h00*p0 + h10*m0 + h01*p1 + h11*m1
    return result

def catmull_rom_2d(img, scale=2):
    """二维 Catmull-Rom (Hermite) 插值"""
    h, w = img.shape
    new_h, new_w = h * scale, w * scale
    
    row_interp = np.zeros((h, new_w))
    x_new = np.linspace(0, w - 1, new_w)
    for i in range(h):
        row_interp[i, :] = catmull_rom_1d(img[i, :], x_new)
        
    result = np.zeros((new_h, new_w))
    y_new = np.linspace(0, h - 1, new_h)
    for j in range(new_w):
        result[:, j] = catmull_rom_1d(row_interp[:, j], y_new)
    return result

def krig_bilateral_upsample(low_res, scale=2, search_radius=2, sigma_c=0.15, nugget=0.08, sill=1.2, range_a=2.0):
    """正宗 KrigBilateral 二维图像上采样"""
    h_low, w_low = low_res.shape
    h_high, w_high = h_low * scale, w_low * scale
    high_res = np.zeros((h_high, w_high))
    
    def variogram(d):
        return nugget + (sill - nugget) * (1.0 - np.exp(-(d**2) / (range_a**2)))

    dy, dx = np.mgrid[-search_radius:search_radius+1, -search_radius:search_radius+1]
    dx_flat, dy_flat = dx.flatten(), dy.flatten()
    num_neighbors = len(dx_flat)
    
    dist_matrix = np.sqrt((dx_flat[:, None] - dx_flat[None, :])**2 + (dy_flat[:, None] - dy_flat[None, :])**2)
    K_left = sill - variogram(dist_matrix)
    padded_low = np.pad(low_res, search_radius, mode='edge')
    
    for py in range(h_high):
        for px in range(w_high):
            ly_float = (py + 0.5) / scale - 0.5
            lx_float = (px + 0.5) / scale - 0.5
            
            ly_int = int(np.clip(np.floor(ly_float), 0, h_low - 1))
            lx_int = int(np.clip(np.floor(lx_float), 0, w_low - 1))
            
            iy, ix = ly_int + search_radius, lx_int + search_radius
            neighbors_val = padded_low[iy - search_radius : iy + search_radius + 1, 
                                       ix - search_radius : ix + search_radius + 1].flatten()
            
            dist_to_target = np.sqrt((dx_flat + ly_int - ly_float)**2 + (dy_flat + lx_int - lx_float)**2)
            K_right = sill - variogram(dist_to_target)
            
            spatial_weights = np.linalg.solve(K_left + 1e-4 * np.eye(num_neighbors), K_right)
            
            center_ref = padded_low[iy, ix]
            range_weights = np.exp(-((neighbors_val - center_ref) ** 2) / (2 * sigma_c ** 2))
            
            combined_weights = spatial_weights * range_weights
            w_sum = np.sum(combined_weights)
            if w_sum <= 1e-6:
                combined_weights = range_weights / (np.sum(range_weights) + 1e-6)
            else:
                combined_weights /= w_sum
                
            high_res[py, px] = np.sum(combined_weights * neighbors_val)
            
    return high_res

# ============ 3. 执行计算与可视化对比 ============
print("🚀 正在计算 Hermite 和 KrigBilateral 插值...")
nearest = zoom(low_img, 2, order=0)
hermite = np.clip(catmull_rom_2d(low_img, scale=2), 0, 1)
krig_real = np.clip(krig_bilateral_upsample(low_img, scale=2, search_radius=2), 0, 1)
print("🎯 计算完成！")

# 绘图
fig, axes = plt.subplots(1, 4, figsize=(22, 8))

methods = [
    ('Ground Truth (无噪参考)', gt_signal),
    ('Nearest (最近邻)', nearest),
    ('Hermite (Catmull-Rom)', hermite),
    ('Authentic KrigBilateral (正宗双边克里金)', krig_real)
]

for ax, (name, img) in zip(axes, methods):
    ax.imshow(img, cmap='gray', vmin=0, vmax=1, interpolation='nearest')
    ax.set_title(name, fontsize=12, fontweight='bold', pad=10)
    ax.axis('off')
    
    # 指标计算
    gy, gx = np.gradient(img)
    edge_strength = np.mean(np.sqrt(gx**2 + gy**2))
    mae = np.mean(np.abs(img - gt_signal))
    
    ax.text(0.5, -0.08, f'边缘锐度: {edge_strength:.4f}\n真实重建误差(MAE): {mae:.4f}', 
            transform=ax.transAxes, ha='center', fontsize=10,
            bbox=dict(boxstyle='round,pad=0.4', facecolor='#F8F9FA', alpha=0.95, edgecolor='#DEE2E6'))

plt.tight_layout()
plt.show()