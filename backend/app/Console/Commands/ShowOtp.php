<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class ShowOtp extends Command
{
    protected $signature = 'otp:show';
    protected $description = 'Show latest OTP from log file';

    public function handle()
    {
        $logPath = storage_path('logs/laravel.log');
        
        if (!file_exists($logPath)) {
            $this->error('Log file not found');
            return 1;
        }

        $content = file_get_contents($logPath);
        
        // Extract OTP dari log (cari pattern 6 digit dalam email)
        preg_match_all('/\b(\d{6})\b/', $content, $matches);
        
        if (empty($matches[1])) {
            $this->warn('No OTP found in log');
            return 0;
        }

        $otps = array_reverse(array_unique($matches[1]));
        
        $this->info('📧 Latest OTPs from log:');
        $this->newLine();
        
        foreach (array_slice($otps, 0, 5) as $otp) {
            $this->line("  🔑 {$otp}");
        }
        
        $this->newLine();
        $this->comment('Use the most recent OTP in your Flutter app');
        
        return 0;
    }
}
