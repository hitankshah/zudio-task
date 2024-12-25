import { create } from 'zustand';
import { Task } from '../types';
import { supabase } from '../lib/supabase';

interface TaskState {
  tasks: Task[];
  loading: boolean;
  createTask: (task: Partial<Task>) => Promise<void>;
  updateTask: (id: string, updates: Partial<Task>) => Promise<void>;
  fetchTasks: () => Promise<void>;
  addCollaborator: (taskId: string, userId: string, role: 'viewer' | 'editor') => Promise<void>;
}

export const useTaskStore = create<TaskState>((set, get) => ({
  tasks: [],
  loading: false,
  createTask: async (task) => {
    const { data, error } = await supabase
      .from('tasks')
      .insert(task)
      .select()
      .single();
    
    if (error) throw error;
    set({ tasks: [...get().tasks, data] });
  },
  updateTask: async (id, updates) => {
    const { error } = await supabase
      .from('tasks')
      .update(updates)
      .eq('id', id);
    
    if (error) throw error;
    set({
      tasks: get().tasks.map((task) =>
        task.id === id ? { ...task, ...updates } : task
      ),
    });
  },
  fetchTasks: async () => {
    set({ loading: true });
    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    set({ tasks: data, loading: false });
  },
  addCollaborator: async (taskId, userId, role) => {
    const { error } = await supabase
      .from('task_collaborators')
      .insert({ task_id: taskId, user_id: userId, role });
    
    if (error) throw error;
  },
}));