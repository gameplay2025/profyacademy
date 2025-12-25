// Supabase Client Initialization
const supabaseUrl = 'https://amgciwtmhoucdrziahob.supabase.co';
const supabaseKey = 'sb_publishable_Jy9axgSNBZbuOIzA-oTQrw_YJPF5hKz';
const supabase = window.supabase.createClient(supabaseUrl, supabaseKey);

// Authentication Functions
async function login(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  return { user: data?.user, error };
}

async function logout() {
  await supabase.auth.signOut();
}

async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

// Profile Functions
async function getUserRole(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', userId)
    .single();
  if (error) {
    console.error('Error fetching user role:', error);
    return null;
  }
  return data?.role;
}

// Materials Functions
async function getMaterials() {
  const { data, error } = await supabase
    .from('materials')
    .select('*')
    .order('created_at', { ascending: false });
  if (error) {
    console.error('Error fetching materials:', error);
    return [];
  }
  return data || [];
}

async function uploadPDF(file, title) {
  const fileName = `${Date.now()}_${file.name}`;
  const { data: uploadData, error: uploadError } = await supabase.storage
    .from('materials')
    .upload(fileName, file);
  if (uploadError) {
    return { data: null, error: uploadError };
  }
  const { data: urlData } = supabase.storage
    .from('materials')
    .getPublicUrl(fileName);
  const { data, error } = await supabase
    .from('materials')
    .insert({ title, type: 'pdf', url: urlData.publicUrl })
    .select()
    .single();
  return { data, error };
}

async function addYouTubeLink(title, url) {
  const { data, error } = await supabase
    .from('materials')
    .insert({ title, type: 'youtube', url })
    .select()
    .single();
  return { data, error };
}

async function deleteMaterial(id) {
  const { data: material } = await supabase
    .from('materials')
    .select('type, url')
    .eq('id', id)
    .single();
  if (material?.type === 'pdf') {
    const fileName = material.url.split('/').pop();
    await supabase.storage.from('materials').remove([fileName]);
  }
  const { error } = await supabase
    .from('materials')
    .delete()
    .eq('id', id);
  return { error };
}

// Schedule Functions
async function getSchedule() {
  const { data, error } = await supabase
    .from('schedule')
    .select('*')
    .order('day', { ascending: true });
  if (error) {
    console.error('Error fetching schedule:', error);
    return [];
  }
  return data || [];
}

async function addScheduleEntry(day, time, subject) {
  const { data, error } = await supabase
    .from('schedule')
    .insert({ day, time, subject })
    .select()
    .single();
  return { data, error };
}

async function updateScheduleEntry(id, day, time, subject) {
  const { data, error } = await supabase
    .from('schedule')
    .update({ day, time, subject })
    .eq('id', id)
    .select()
    .single();
  return { data, error };
}

async function deleteScheduleEntry(id) {
  const { error } = await supabase
    .from('schedule')
    .delete()
    .eq('id', id);
  return { error };
}
