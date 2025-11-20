# Image Download and Compression Script

This script downloads and compresses images for the OnboardingScreen.

## Prerequisites

Install required Python packages:
```bash
pip install requests pillow
```

## Usage

Run the script from the project root:
```bash
python scripts/download_and_compress_images.py
```

The script will:
1. Download all 26 images from Unsplash URLs
2. Compress them to 400x400px maximum size
3. Save them as JPEG files with 75% quality
4. Save them to `assets/images/onboarding/` directory

## Output

Images will be saved as:
- `assets/images/onboarding/onboarding_01.jpg`
- `assets/images/onboarding/onboarding_02.jpg`
- ... and so on up to `onboarding_26.jpg`

## Notes

- Images are compressed to reduce app size
- Original images are not preserved
- If an image fails to download, the script will continue with the next one
- The script shows progress and compression statistics

