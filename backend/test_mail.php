<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

try {
    \Illuminate\Support\Facades\Mail::raw('Test Message', function($msg) {
        $msg->to('familygroupMANGAN@gmail.com')->subject('Test OTP');
    });
    echo "Email sent successfully.\n";
} catch (\Exception $e) {
    echo "Error sending email: " . $e->getMessage() . "\n";
}
