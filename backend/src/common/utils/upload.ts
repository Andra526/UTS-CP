import { BadRequestException } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { existsSync, mkdirSync, unlinkSync } from 'fs';
import { diskStorage } from 'multer';
import { extname, join } from 'path';

/** Folder penyimpanan foto. Bisa diubah lewat env UPLOAD_DIR. */
export const UPLOAD_DIR = process.env.UPLOAD_DIR ?? join(process.cwd(), 'uploads');

const ALLOWED: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

/** Opsi multer: hanya JPG/PNG/WEBP, maks 3 MB per file. */
export const imageUploadOptions = {
  storage: diskStorage({
    destination: (_req, _file, cb) => {
      if (!existsSync(UPLOAD_DIR)) mkdirSync(UPLOAD_DIR, { recursive: true });
      cb(null, UPLOAD_DIR);
    },
    filename: (_req, file, cb) => {
      cb(null, `${Date.now()}-${randomBytes(6).toString('hex')}${ALLOWED[file.mimetype] ?? extname(file.originalname)}`);
    },
  }),
  limits: { fileSize: 3 * 1024 * 1024 },
  fileFilter: (_req: unknown, file: { mimetype: string }, cb: (e: Error | null, ok: boolean) => void) => {
    if (ALLOWED[file.mimetype]) cb(null, true);
    else cb(new BadRequestException('Gambar harus berformat JPG, PNG, atau WEBP'), false);
  },
};

/** URL relatif yang disimpan di database; klien menambahkan alamat server. */
export const fileUrl = (file: { filename: string }) => `/uploads/${file.filename}`;

/** Hapus file fisik bila URL-nya berasal dari upload kita (bukan link luar). */
export function removeUploaded(url: string | null | undefined) {
  if (!url || !url.startsWith('/uploads/')) return;
  const target = join(UPLOAD_DIR, url.replace('/uploads/', ''));
  if (target.startsWith(UPLOAD_DIR) && existsSync(target)) {
    try {
      unlinkSync(target);
    } catch {
      /* abaikan */
    }
  }
}
