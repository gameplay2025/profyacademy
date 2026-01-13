// Supabase Configuration
const SUPABASE_URL = 'https://iztiuutsakynooqiqxth.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml6dGl1dXRzYWt5bm9vcWlxeHRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMjM0NjcsImV4cCI6MjA4Mzc5OTQ2N30.HawCEq7CezBOrAdXSVgTnX0s4x-oiDP_JviMGvNJ2ok';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Auth state
let currentUser = null;
let userProfile = null;

// Initialize auth
async function initAuth() {
    const { data: { session } } = await supabase.auth.getSession();
    if (session) {
        currentUser = session.user;
        await loadUserProfile();
    }
    
    // Listen for auth changes
    supabase.auth.onAuthStateChange(async (event, session) => {
        if (event === 'SIGNED_IN' && session) {
            currentUser = session.user;
            await loadUserProfile();
            handleAuthStateChange();
        } else if (event === 'SIGNED_OUT') {
            currentUser = null;
            userProfile = null;
            handleAuthStateChange();
        }
    });
    
    handleAuthStateChange();
}

// Load user profile from database
async function loadUserProfile() {
    if (!currentUser) return null;
    
    const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', currentUser.id)
        .single();
    
    if (error) {
        console.error('Error loading profile:', error);
        return null;
    }
    
    userProfile = data;
    return data;
}

// Sign up with email
async function signUpWithEmail(email, password, studentName, gradeLevels) {
    const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
            data: {
                student_name: studentName,
                grade_levels: gradeLevels,
                role: 'user',
                is_approved: false
            }
        }
    });
    
    if (error) throw error;
    return data;
}

// Sign in with email
async function signInWithEmail(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
    });
    
    if (error) throw error;
    return data;
}

// Sign in with Google
async function signInWithGoogle() {
    const { data, error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
            redirectTo: window.location.origin + '/index.html'
        }
    });
    
    if (error) throw error;
    return data;
}

// Sign out
async function signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
}

// Check if user is admin
function isAdmin() {
    return userProfile?.role === 'admin';
}

// Check if user is approved
function isApproved() {
    return userProfile?.is_approved === true;
}

// Get user's allowed grade levels
function getAllowedGradeLevels() {
    return userProfile?.grade_levels || [];
}

// Admin: Get all pending users
async function getPendingUsers() {
    if (!isAdmin()) throw new Error('Unauthorized');
    
    const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('is_approved', false)
        .neq('role', 'admin')
        .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
}

// Admin: Get all users
async function getAllUsers() {
    if (!isAdmin()) throw new Error('Unauthorized');
    
    const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
}

// Admin: Approve user
async function approveUser(userId) {
    if (!isAdmin()) throw new Error('Unauthorized');
    
    const { data, error } = await supabase
        .from('user_profiles')
        .update({ is_approved: true })
        .eq('id', userId)
        .select()
        .single();
    
    if (error) throw error;
    return data;
}

// Admin: Reject/Delete user
async function rejectUser(userId) {
    if (!isAdmin()) throw new Error('Unauthorized');
    
    const { error } = await supabase
        .from('user_profiles')
        .delete()
        .eq('id', userId);
    
    if (error) throw error;
}

// Admin: Update user grade levels
async function updateUserGradeLevels(userId, gradeLevels) {
    if (!isAdmin()) throw new Error('Unauthorized');
    
    const { data, error } = await supabase
        .from('user_profiles')
        .update({ grade_levels: gradeLevels })
        .eq('id', userId)
        .select()
        .single();
    
    if (error) throw error;
    return data;
}

// Handle auth state change - to be overridden by page
function handleAuthStateChange() {
    // Override this function in your page
    console.log('Auth state changed:', { currentUser, userProfile });
}

// Update profile after Google sign-in (for student name and grade levels)
async function updateProfileAfterOAuth(studentName, gradeLevels) {
    if (!currentUser) throw new Error('Not authenticated');
    
    const { data, error } = await supabase
        .from('user_profiles')
        .update({
            student_name: studentName,
            grade_levels: gradeLevels
        })
        .eq('id', currentUser.id)
        .select()
        .single();
    
    if (error) throw error;
    userProfile = data;
    return data;
}

// Check if profile needs completion (after OAuth)
function needsProfileCompletion() {
    return userProfile && (!userProfile.student_name || userProfile.grade_levels.length === 0);
}
