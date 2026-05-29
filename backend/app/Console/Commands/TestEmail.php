<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Mail;

class TestEmail extends Command
{
    protected $signature = 'mail:test {email}';
    protected $description = 'Test email configuration';

    public function handle()
    {
        $email = $this->argument('email');

        $this->info("Sending test email to {$email}...");

        try {
            Mail::raw('Test email dari MANGAN. Konfigurasi email berhasil! 🎉', function ($message) use ($email) {
                $message->to($email)
                        ->subject('Test Email - Mangansage');
            });

            $this->info('✅ Email sent successfully!');
            $this->info('Check your inbox at: ' . $email);
        } catch (\Exception $e) {
            $this->error('❌ Failed to send email:');
            $this->error($e->getMessage());
            return 1;
        }

        return 0;
    }
}
