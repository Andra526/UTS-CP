export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string | null;
  role: 'MEMBER' | 'TRAINER' | 'ADMIN';
  managedGymId?: string | null;
}

export interface Facility { id: string; label: string; icon: string }
export interface GymImage { id: string; url: string }
export interface Plan {
  id: string;
  name: string;
  price: number;
  durationDays: number;
  note: string;
  isPopular: boolean;
}
export interface Gym {
  id: string;
  name: string;
  city: string;
  address: string;
  openHours: string;
  phone: string;
  imageUrl: string;
  facilities: Facility[];
  images: GymImage[];
  plans: Plan[];
}

export interface Dashboard {
  gymName: string;
  activeMembers: number;
  trainers: number;
  sessionsThisWeek: number;
  revenueTotal: number;
  revenueThisMonth: number;
  pendingBookings: number;
  checklist: { hasPlans: boolean; hasPhotos: boolean; hasTrainers: boolean };
}

export interface Trainer {
  id: string;
  userId: string;
  specialization: string;
  experienceYears: number;
  bio: string;
  rating: number;
  isActive: boolean;
  user: { id: string; name: string; email: string; phone?: string | null };
  _count: { bookings: number };
}

export interface Membership {
  id: string;
  price: number;
  startDate: string;
  endDate: string;
  status: 'ACTIVE' | 'EXPIRED';
  daysLeft: number;
  user: { id: string; name: string; email: string; phone?: string | null };
  plan: { id: string; name: string };
}

export interface Booking {
  id: string;
  scheduledAt: string;
  durationMin: number;
  note: string;
  goalType: string;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'COMPLETED' | 'CANCELLED';
  client: { id: string; name: string; email: string };
  trainer: { id: string; user: { name: string } };
  session: { attendance: string; intensity: number; notes: string } | null;
}
