# 📸 Screenshot Guide - SiLAKES Scanner

Panduan untuk mengambil screenshot aplikasi untuk dokumentasi atau presentasi.

---

## 📱 Required Screenshots

### 1. **Splash Screen / Dashboard**
**File**: `screenshot_01_dashboard.png`

**What to show:**
- Logo SiLAKES Scanner di AppBar
- Hero section dengan gradient biru muda
- Tombol "Mulai Scan" yang prominent
- Riwayat scan (jika ada)

**Tips:**
- Pastikan ada 2-3 history items untuk demo
- Clean screen, no notifications
- Portrait orientation

---

### 2. **Camera Screen**
**File**: `screenshot_02_camera.png`

**What to show:**
- Full camera preview
- KTP frame guide overlay (biru dengan corner indicators)
- Top bar: Back button, title "Scan KTP", Flash toggle
- Bottom bar: Gallery icon, Capture button (big white circle)
- Instruction text: "Posisikan KTP di dalam frame"

**Tips:**
- Position real KTP or printed KTP in frame
- Good lighting
- Frame guide should be visible clearly

---

### 3. **Loading OCR**
**File**: `screenshot_03_loading.png`

**What to show:**
- Animated loading indicator (dots wave)
- Text: "Memproses gambar..."
- Subtext: "Mengekstrak data KTP dengan AI"

**Tips:**
- Take screenshot quickly after capture
- Should show the blue loading animation

---

### 4. **Preview & Edit Form**
**File**: `screenshot_04_preview_edit.png`

**What to show:**
- KTP image preview at top
- Form dengan data terisi dari OCR
- Sections: Data Identitas, Alamat, Data Lainnya
- Tombol "Simpan Data" di bottom
- Scrollable content

**Tips:**
- Fill with realistic data
- Show at least 2 sections in viewport
- Form should look clean and organized

---

### 5. **History Detail Dialog**
**File**: `screenshot_05_history_detail.png`

**What to show:**
- Dialog with patient detail
- Icon person di header
- All patient fields displayed
- Close button

**Tips:**
- Tap history item to open dialog
- Should show complete data
- Clean and readable layout

---

### 6. **Success Flow (Sequence)**
**File**: `screenshot_06_success_flow.png` (combo)

**Sequence to show:**
1. Scan KTP
2. OCR Processing
3. Edit & Confirm
4. Success message
5. Data in History

**Tips:**
- Create a flow diagram or grid
- Show step-by-step process
- Annotations with arrows

---

## 🎨 Screenshot Best Practices

### Device Setup

**Recommended Device:**
- Android device with AMOLED screen
- Clean home screen (no notifications)
- Full battery icon
- Airplane mode ON (no notification icons)

**Screen Resolution:**
- Minimum: 1080x1920 (Full HD)
- Recommended: 1440x2960 (Quad HD)

### Before Taking Screenshot

```bash
# Enable demo mode (Android)
adb shell settings put global sysui_demo_allowed 1

# Set time to 12:00
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1200

# Set battery to 100%
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false

# Remove notifications
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
```

### Taking Screenshot

**Method 1: From Device**
- Power + Volume Down (bersamaan)
- Screenshot saved to Gallery

**Method 2: From ADB**
```bash
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

**Method 3: From Android Studio**
- Tools → Device File Explorer
- Click camera icon

### After Taking Screenshot

**Cleanup:**
```bash
# Disable demo mode
adb shell settings put global sysui_demo_allowed 0
```

---

## 🖼️ Screenshot Editing

### Required Edits

1. **Crop** - Remove unnecessary parts
2. **Resize** - Consistent size across all screenshots
3. **Frame** - Optional: Add device frame
4. **Annotate** - Add arrows, circles, text if needed

### Recommended Tools

**Free:**
- **Snapseed** (Mobile)
- **GIMP** (Desktop)
- **Paint.NET** (Windows)

**Paid:**
- **Adobe Photoshop**
- **Sketch** (Mac)
- **Figma** (Web-based)

### Device Frame

Add professional device frame:
- https://mockuphone.com/
- https://screenshots.pro/
- https://deviceframes.com/

---

## 📏 Screenshot Specifications

### For README.md

**Size:**
- Width: 300-400px (thumbnail)
- Format: PNG with compression

**Layout:**
```markdown
<p align="center">
  <img src="screenshots/dashboard.png" width="250"/>
  <img src="screenshots/camera.png" width="250"/>
  <img src="screenshots/preview.png" width="250"/>
</p>
```

### For Play Store

**Required Sizes:**
- Phone: 1080x1920 (16:9)
- Tablet: 1200x1920 (16:10)
- Minimum: 2 screenshots
- Maximum: 8 screenshots

**Formats:**
- PNG or JPEG
- Max 8MB per file
- 24-bit RGB

---

## 📂 File Organization

```
silakes_scanner/
├── screenshots/
│   ├── raw/                    # Original screenshots
│   │   ├── dashboard_raw.png
│   │   ├── camera_raw.png
│   │   └── ...
│   ├── edited/                 # Processed screenshots
│   │   ├── 01_dashboard.png
│   │   ├── 02_camera.png
│   │   ├── 03_loading.png
│   │   ├── 04_preview.png
│   │   └── 05_history.png
│   └── framed/                 # With device frames
│       ├── dashboard_framed.png
│       └── ...
└── docs/
    └── images/                 # For documentation
        └── ...
```

---

## 🎬 Video Demo (Optional)

### Screen Recording

**From Device:**
- Use built-in screen recorder
- Or install **AZ Screen Recorder**

**From ADB:**
```bash
adb shell screenrecord /sdcard/demo.mp4
# Record max 3 minutes
# Tap CTRL+C to stop

adb pull /sdcard/demo.mp4
```

### Video Specs

- **Resolution**: 1080p minimum
- **FPS**: 30fps or 60fps
- **Duration**: 30-60 seconds
- **Format**: MP4 (H.264)
- **Audio**: Optional (music or narration)

### Recommended Flow

1. **0-5s**: Splash/Dashboard
2. **5-15s**: Camera screen (position KTP)
3. **15-25s**: Take photo → Loading
4. **25-40s**: Preview & Edit form
5. **40-50s**: Submit → Success
6. **50-60s**: View History

---

## 📱 Demo Data

### Test KTP Data (For Screenshots)

```
NIK: 3529012345678901
Nama: AHMAD RIDWAN HAKIM
Tempat Lahir: SUMENEP
Tanggal Lahir: 15-08-1990
Jenis Kelamin: LAKI-LAKI
Alamat: JL. TRUNOJOYO NO. 45
RT/RW: 003/002
Kel/Desa: KOLOR
Kecamatan: KOTA SUMENEP
Agama: ISLAM
Status Perkawinan: KAWIN
Pekerjaan: WIRASWASTA
Kewarganegaraan: WNI
Berlaku Hingga: SEUMUR HIDUP
```

**Note:** Gunakan data dummy untuk screenshot, JANGAN gunakan KTP asli!

---

## ✅ Screenshot Checklist

Sebelum publish, pastikan:

- [ ] All 5 main screenshots taken
- [ ] Screenshots are clear and readable
- [ ] No sensitive data visible
- [ ] Consistent device/resolution
- [ ] Proper lighting and contrast
- [ ] No typos in visible text
- [ ] Status bar clean (demo mode)
- [ ] Battery 100% (demo mode)
- [ ] Time set to 12:00 (demo mode)
- [ ] Portrait orientation
- [ ] Professional quality
- [ ] File size optimized (<1MB each)

---

## 🎨 Branding Guidelines

### Colors
- Primary: #4FC3F7 (Light Blue)
- Accent: Use sparingly
- Background: White or light gray

### Logo
- Always visible in AppBar
- High resolution (no pixelation)
- Proper spacing

### Typography
- Font: Poppins (consistent)
- Size: Readable at thumbnail size
- Contrast: Good readability

---

## 📤 Export & Upload

### For GitHub README
```bash
# Optimize images
# Use tinypng.com or similar

# Upload to GitHub
# In your README.md:
![Dashboard](screenshots/dashboard.png)
```

### For Play Store
```bash
# Upload directly to Play Console
# Under "Store presence" → "Main store listing"
```

### For Documentation
```bash
# Copy to docs folder
cp screenshots/edited/*.png docs/images/
```

---

## 📞 Need Help?

Gunakan tools online:
- **Remove background**: remove.bg
- **Compress**: tinypng.com
- **Resize**: picresize.com
- **Add frame**: mockuphone.com

---

**Last Updated**: 2024-11-18
