export type User = {
  id: string;
  email: string;
  full_name: string | null;
  avatar_url: string | null;
  role: 'admin' | 'manager' | 'member';
  created_at: string;
};

export type Task = {
  id: string;
  title: string;
  description: string | null;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'todo' | 'in_progress' | 'review' | 'done';
  due_date: string | null;
  created_by: string;
  assigned_to: string | null;
  created_at: string;
};

export type TaskCollaborator = {
  task_id: string;
  user_id: string;
  role: 'viewer' | 'editor';
  created_at: string;
};

export type TaskComment = {
  id: string;
  task_id: string;
  user_id: string;
  content: string;
  created_at: string;
};