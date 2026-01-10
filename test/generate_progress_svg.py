import sys
import math

def generate_progress_svg(total, passed, filename="test262_progress.svg"):
    if total == 0:
        percentage = 0
    else:
        percentage = (passed / total) * 100

    # 颜色逻辑
    if percentage < 50:
        color = "#ff4d4f" # Red
    elif percentage < 90:
        color = "#faad14" # Yellow
    else:
        color = "#52c41a" # Green

    # SVG 参数
    size = 120
    stroke_width = 10
    radius = (size - stroke_width) / 2
    center = size / 2
    circumference = 2 * math.pi * radius
    offset = circumference - (percentage / 100) * circumference

    svg_content = f"""<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" xmlns="http://www.w3.org/2000/svg">
  <!-- Background Circle -->
  <circle cx="{center}" cy="{center}" r="{radius}" fill="#ffffff" stroke="#f0f0f0" stroke-width="{stroke_width}" />
  
  <!-- Progress Circle -->
  <circle cx="{center}" cy="{center}" r="{radius}" fill="none" stroke="{color}" stroke-width="{stroke_width}"
          stroke-dasharray="{circumference}" stroke-dashoffset="{offset}" transform="rotate(-90 {center} {center})" stroke-linecap="round" />
  
  <!-- Text -->
  <text x="50%" y="45%" text-anchor="middle" dy=".3em" font-family="Arial, sans-serif" font-size="20" fill="#333" font-weight="bold">{percentage:.1f}%</text>
  <text x="50%" y="65%" text-anchor="middle" dy=".3em" font-family="Arial, sans-serif" font-size="10" fill="#666">{passed}/{total}</text>
</svg>
"""
    
    with open(filename, "w") as f:
        f.write(svg_content)
    print(f"Generated {filename} with {percentage:.1f}% ({passed}/{total})")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 generate_progress_svg.py <total> <passed> [filename]")
        sys.exit(1)
    
    try:
        total_arg = int(sys.argv[1])
        passed_arg = int(sys.argv[2])
        out_file = sys.argv[3] if len(sys.argv) > 3 else "test262_progress.svg"
        generate_progress_svg(total_arg, passed_arg, out_file)
    except ValueError:
        print("Error: total and passed must be integers")
        sys.exit(1)