<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$request = new \Illuminate\Http\Request();
$request->merge(['email' => 'galangskywalker@gmail.com']);
$controller = new \App\Http\Controllers\Auth\PasswordResetController();
$res = $controller->forgotPassword($request);
echo "Response: " . $res->getContent() . "\n";
