-- Fix pg_cron job to include proper authentication
-- Run this in your Supabase SQL Editor

-- First, unschedule the old job
SELECT cron.unschedule('mla-daily-scrape');

-- Create new job with proper authentication headers
SELECT cron.schedule(
  'mla-daily-scrape',
  '0 1 * * *', -- Daily at 1 AM
  $$
  SELECT net.http_post(
    url:='https://skgdpvsxwbtnxpgviteg.supabase.co/functions/v1/mla-scraper',
    headers:=jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'sb_publishable_7a2QWHYFG4eWlRqAvmidKg_D8170ZDN',
      'Authorization', 'Bearer sb_publishable_7a2QWHYFG4eWlRqAvmidKg_D8170ZDN'
    )
  );
  $$
);

-- Verify it's scheduled
SELECT * FROM cron.job WHERE jobname = 'mla-daily-scrape';

-- Trigger it manually to test
SELECT net.http_post(
  url:='https://skgdpvsxwbtnxpgviteg.supabase.co/functions/v1/mla-scraper',
  headers:=jsonb_build_object(
    'Content-Type', 'application/json',
    'apikey', 'sb_publishable_7a2QWHYFG4eWlRqAvmidKg_D8170ZDN',
    'Authorization', 'Bearer sb_publishable_7a2QWHYFG4eWlRqAvmidKg_D8170ZDN'
  )
);
