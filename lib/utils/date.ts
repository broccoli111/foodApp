export function toISODate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function daysFromNow(days: number): string {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return toISODate(date);
}

export function daysUntil(date: string | null): number | null {
  if (!date) return null;
  const today = new Date(toISODate(new Date())).getTime();
  const target = new Date(date).getTime();
  return Math.ceil((target - today) / 86400000);
}

export function isExpiringSoon(date: string | null, windowDays = 5): boolean {
  const days = daysUntil(date);
  return days !== null && days >= 0 && days <= windowDays;
}

export function startOfWeek(date = new Date()): Date {
  const copy = new Date(date);
  const day = copy.getDay();
  const diff = copy.getDate() - day;
  copy.setDate(diff);
  copy.setHours(0, 0, 0, 0);
  return copy;
}

export function weekDates(date = new Date()): string[] {
  const start = startOfWeek(date);
  return Array.from({ length: 7 }, (_, index) => {
    const item = new Date(start);
    item.setDate(start.getDate() + index);
    return toISODate(item);
  });
}

export function shortWeekday(date: string): string {
  return new Intl.DateTimeFormat("en", { weekday: "short" }).format(new Date(`${date}T12:00:00`));
}
