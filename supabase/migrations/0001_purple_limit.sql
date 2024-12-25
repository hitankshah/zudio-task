/*
  # Initial Zudio Schema Setup

  1. New Tables
    - users
      - id (uuid, primary key)
      - email (text)
      - full_name (text)
      - avatar_url (text)
      - role (text)
      - created_at (timestamp)
    
    - tasks
      - id (uuid, primary key)
      - title (text)
      - description (text)
      - priority (text)
      - status (text)
      - due_date (timestamp)
      - created_by (uuid, references users)
      - assigned_to (uuid, references users)
      - created_at (timestamp)
    
    - task_collaborators
      - task_id (uuid, references tasks)
      - user_id (uuid, references users)
      - role (text)
      - created_at (timestamp)
    
    - task_comments
      - id (uuid, primary key)
      - task_id (uuid, references tasks)
      - user_id (uuid, references users)
      - content (text)
      - created_at (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Users table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT auth.uid(),
  email text UNIQUE NOT NULL,
  full_name text,
  avatar_url text,
  role text DEFAULT 'member' CHECK (role IN ('admin', 'manager', 'member')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read all users"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Tasks table
CREATE TABLE tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  priority text NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status text NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'review', 'done')),
  due_date timestamptz,
  created_by uuid REFERENCES users(id) NOT NULL,
  assigned_to uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read tasks they are assigned to or collaborate on"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    auth.uid() = created_by OR
    auth.uid() = assigned_to OR
    EXISTS (
      SELECT 1 FROM task_collaborators
      WHERE task_id = tasks.id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update tasks they own or are assigned to"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = created_by OR
    auth.uid() = assigned_to OR
    EXISTS (
      SELECT 1 FROM task_collaborators
      WHERE task_id = tasks.id AND user_id = auth.uid() AND role = 'editor'
    )
  );

-- Task collaborators table
CREATE TABLE task_collaborators (
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('viewer', 'editor')),
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (task_id, user_id)
);

ALTER TABLE task_collaborators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read collaborators for their tasks"
  ON task_collaborators FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      WHERE id = task_id AND (
        created_by = auth.uid() OR
        assigned_to = auth.uid() OR
        EXISTS (
          SELECT 1 FROM task_collaborators tc
          WHERE tc.task_id = tasks.id AND tc.user_id = auth.uid()
        )
      )
    )
  );

-- Task comments table
CREATE TABLE task_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id),
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read comments on their tasks"
  ON task_comments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      WHERE id = task_id AND (
        created_by = auth.uid() OR
        assigned_to = auth.uid() OR
        EXISTS (
          SELECT 1 FROM task_collaborators
          WHERE task_id = tasks.id AND user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Users can create comments on tasks they have access to"
  ON task_comments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks
      WHERE id = task_id AND (
        created_by = auth.uid() OR
        assigned_to = auth.uid() OR
        EXISTS (
          SELECT 1 FROM task_collaborators
          WHERE task_id = tasks.id AND user_id = auth.uid()
        )
      )
    )
  );