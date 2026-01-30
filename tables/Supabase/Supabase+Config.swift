import Foundation
import Auth
import PostgREST
import Realtime

enum SupabaseConfig {
    // TODO: Replace these with your actual Supabase credentials
    static let projectURL = URL(string: "https://wfhnsoretclgrvsagbyj.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmaG5zb3JldGNsZ3J2c2FnYnlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4NDIyNTEsImV4cCI6MjA4NDQxODI1MX0.aVZMrswUWwgsnf_8ndaZz0_3eFz9UDhEt3oZFR00Mu0"
}

// We'll create the client in SupabaseManager instead
