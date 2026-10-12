import os
from PIL import Image

def optimize_game_images():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    games_dir = os.path.join(root_dir, 'web', 'assets', 'games')
    
    if not os.path.isdir(games_dir):
        print(f"Diretório não encontrado: {games_dir}")
        return

    files = [f for f in os.listdir(games_dir) if f.endswith('.jpg')]
    print(f"Otimizando {len(files)} imagens de jogos em {games_dir}...")

    total_orig = 0
    total_thumb = 0
    total_hero = 0

    for f in files:
        base = os.path.splitext(f)[0]
        jpg_path = os.path.join(games_dir, f)
        orig_size = os.path.getsize(jpg_path)
        total_orig += orig_size
        
        with Image.open(jpg_path) as img:
            img_rgb = img.convert('RGB')
            w, h = img_rgb.size

            # 1. Thumbnail quadrado 480x480 com corte central
            min_dim = min(w, h)
            left = (w - min_dim) // 2
            top = (h - min_dim) // 2
            crop_square = img_rgb.crop((left, top, left + min_dim, top + min_dim))
            thumb = crop_square.resize((480, 480), Image.Resampling.LANCZOS)
            thumb_path = os.path.join(games_dir, f'{base}-thumb.webp')
            thumb.save(thumb_path, 'WEBP', quality=82, method=6)
            total_thumb += os.path.getsize(thumb_path)
            
            # 2. Hero banner com max 1280px
            scale = min(1280 / w, 1280 / h, 1.0)
            hero_w = int(w * scale)
            hero_h = int(h * scale)
            hero = img_rgb.resize((hero_w, hero_h), Image.Resampling.LANCZOS)
            hero_path = os.path.join(games_dir, f'{base}.webp')
            hero.save(hero_path, 'WEBP', quality=82, method=6)
            total_hero += os.path.getsize(hero_path)

    print(f"Total original: {total_orig / (1024*1024):.2f} MB")
    print(f"Total thumbnails: {total_thumb / (1024*1024):.2f} MB ({100*(1 - total_thumb/total_orig):.1f}% redução)")
    print(f"Total heroes: {total_hero / (1024*1024):.2f} MB ({100*(1 - total_hero/total_orig):.1f}% redução)")
    print("Otimização concluída com sucesso!")

if __name__ == '__main__':
    optimize_game_images()
