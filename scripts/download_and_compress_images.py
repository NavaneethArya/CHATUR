#!/usr/bin/env python3
"""
Script to download and compress images for OnboardingScreen
Requires: pip install requests pillow
"""

import os
import requests
from PIL import Image
import io
from pathlib import Path

# Image URLs from OnboardingScreen
image_urls = [
    "https://images.unsplash.com/photo-1610433605854-32371a7aa495?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwZmFybWluZ3xlbnwxfHx8fDE3NjM1MjE3NTJ8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1759738098462-90ffac98c554?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjB2aWxsYWdlJTIwY29tbXVuaXR5fGVufDF8fHx8MTc2MzQ0MDAzN3ww&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1718830243435-a4c469bab12e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwd29ya2Vyc3xlbnwxfHx8fDE3NjM1MjE3NTN8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1681226298721-88cdb4096e5f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBhZ3JpY3VsdHVyZSUyMGZpZWxkc3xlbnwxfHx8fDE3NjM1MjE3NTN8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1650726583448-dda0065f2f11?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwY3JhZnRzbWVufGVufDF8fHx8MTc2MzUyMTc1M3ww&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1703922055338-1bf44533da53?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjB2aWxsYWdlJTIwbGlmZXxlbnwxfHx8fDE3NjM1MjE3NTN8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1640292343595-889db1c8262e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYSUyMHRyYWRpdGlvbmFsJTIwc2tpbGxzfGVufDF8fHx8MTc2MzUyMTc1M3ww&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1707721690544-781fe6ede937?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwdGVjaG5vbG9neXxlbnwxfHx8fDE3NjM1MjE3NTN8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1629288465751-07e42186084f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBmYXJtZXIlMjB3b3JraW5nfGVufDF8fHx8MTc2MzQyODMzNHww&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1570966096801-ca0ca3352ea8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYSUyMHJ1cmFsJTIwd29tZW58ZW58MXx8fHwxNzYzNTIxNzUzfDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1699799085041-e288623615ed?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBoYW5kaWNyYWZ0cyUyMHJ1cmFsfGVufDF8fHx8MTc2MzUyMTc1M3ww&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1615637765047-c156d0d78869?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYSUyMHZpbGxhZ2UlMjBtYXJrZXR8ZW58MXx8fHwxNzYzNTIxNzU0fDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1522661067900-ab829854a57f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwZWR1Y2F0aW9ufGVufDF8fHx8MTc2MzUyMTc1NHww&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1626358971654-ec3e1eb0439a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBwYW5jaGF5YXQlMjBjb21tdW5pdHl8ZW58MXx8fHwxNzYzNTIxNzU0fDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1489942986787-cded4ecf962e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjB2aWxsYWdlJTIwY2hpbGRyZW58ZW58MXx8fHwxNzYzNTIxNzU0fDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1759738102266-bab1d130b557?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwYXJ0aXNhbnN8ZW58MXx8fHwxNzYzNTIxNzU0fDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1685023620523-9c726f2c499b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYSUyMHRyYWRpdGlvbmFsJTIwZmFybWluZ3xlbnwxfHx8fDE3NjM1MjE3NTR8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1739185127141-bb4aa70ad22a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwd2VhdmluZ3xlbnwxfHx8fDE3NjM1MjE3NTR8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1580746453801-37b0bc56f3b4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjB2aWxsYWdlJTIwd29tZW4lMjBlbXBvd2VybWVudHxlbnwxfHx8fDE3NjM1MjE3NTR8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1594382029590-64c582afe6c2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYSUyMHJ1cmFsJTIwcG90dGVyeXxlbnwxfHx8fDE3NjM1MjE3NTR8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1698937051291-356eaf4ca3f5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBhZ3JpY3VsdHVyZSUyMGhhcnZlc3R8ZW58MXx8fHwxNzYzNDgzNDQ3fDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1598972676363-683a7b5845a5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwY2FycGVudHJ5fGVufDF8fHx8MTc2MzUyMTc1NHww&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1595243880357-bcf8de1be94f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYSUyMHZpbGxhZ2UlMjBnYXRoZXJpbmd8ZW58MXx8fHwxNzYzNTIxNzU0fDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1669556289350-0e2480fe190e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydXJhbCUyMGluZGlhJTIwdGV4dGlsZXN8ZW58MXx8fHwxNzYzNTIxNzU1fDA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1606203452426-f5af98e6f96e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYW4lMjBmYXJtZXIlMjBwb3J0cmFpdHxlbnwxfHx8fDE3NjM1MjE3NTV8MA&ixlib=rb-4.1.0&q=80&w=1080",
    "https://images.unsplash.com/photo-1594382029590-64c582afe6c2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxpbmRpYSUyMHJ1cmFsJTIwcG90dGVyeXxlbnwxfHx8fDE3NjM1MjE3NTR8MA&ixlib=rb-4.1.0&q=80&w=1080",
]

def download_and_compress_image(url, output_path, max_size=(400, 400), quality=75):
    """Download and compress an image"""
    try:
        print(f"Downloading: {url[:50]}...")
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        # Open image
        img = Image.open(io.BytesIO(response.content))
        
        # Convert to RGB if necessary (for JPEG)
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = background
        
        # Resize if larger than max_size
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # Save compressed
        img.save(output_path, 'JPEG', quality=quality, optimize=True)
        
        original_size = len(response.content)
        compressed_size = os.path.getsize(output_path)
        compression_ratio = (1 - compressed_size / original_size) * 100
        
        print(f"  Saved: {output_path.name} ({compressed_size/1024:.1f}KB, {compression_ratio:.1f}% reduction)")
        return True
    except Exception as e:
        print(f"  Error: {e}")
        return False

def main():
    # Create output directory
    output_dir = Path("assets/images/onboarding")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"Downloading and compressing {len(image_urls)} images...")
    print(f"Output directory: {output_dir}\n")
    
    success_count = 0
    for i, url in enumerate(image_urls, 1):
        filename = f"onboarding_{i:02d}.jpg"
        output_path = output_dir / filename
        
        if download_and_compress_image(url, output_path):
            success_count += 1
    
    print(f"\nCompleted: {success_count}/{len(image_urls)} images downloaded and compressed")
    print(f"\nImages saved to: {output_dir}")
    print("\nNext steps:")
    print("1. Update pubspec.yaml to include the onboarding images")
    print("2. Update OnboardingScreen.dart to use local assets")

if __name__ == "__main__":
    main()

