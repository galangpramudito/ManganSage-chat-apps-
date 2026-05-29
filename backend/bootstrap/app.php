<?php

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Cloud Run / Caddy / nginx — trust SEMUA proxy upstream supaya
        // `$request->ip()` baca real client IP dari `X-Forwarded-For`.
        // Tanpa ini rate limiter pakai IP load balancer = throttle global,
        // bukan per-client.
        $middleware->trustProxies(at: '*');

        // Cegah middleware `auth` mencoba redirect ke route `login` (yang tidak
        // ada — kita API-only). Mengembalikan null memaksa middleware untuk
        // throw AuthenticationException langsung → ditangkap renderable di
        // bawah → balas 401 JSON.
        $middleware->redirectGuestsTo(fn () => null);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );

        // Untuk endpoint API, AuthenticationException harus selalu balas 401 JSON
        // — TIDAK redirect ke route `login` yang memang tidak ada (kita API-only).
        // Default Laravel mengandalkan `Accept: application/json` header untuk
        // memilih shape; kita paksa via path.
        $exceptions->renderable(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json(['message' => $e->getMessage()], 401);
            }

            return null; // biarkan Laravel handle untuk web routes (jika nanti ada).
        });
    })->create();
