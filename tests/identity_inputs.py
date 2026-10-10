"""Synthetic, nonsecret configuration used by resolver and real CLI contract tests."""
APP_UPDATE = {
    'image': 'acrhdshareddev.azurecr.io/honeydrunk-identity-api@sha256:' + 'a' * 64,
    'authority': 'https://example.ciamlogin.com/example.onmicrosoft.com/v2.0',
    'issuer': 'https://example.ciamlogin.com/11111111-1111-1111-1111-111111111111/v2.0',
    'audience': '11111111-1111-1111-1111-111111111111',
    'mobileClientId': '22222222-2222-2222-2222-222222222222',
    'apiScope': 'api://11111111-1111-1111-1111-111111111111/access_as_user',
    'graphTenantId': '33333333-3333-3333-3333-333333333333',
    'graphClientId': '44444444-4444-4444-4444-444444444444',
    'graphCertificateSecretName': 'identity-graph-certificate',
    'allowedOrigins': ['https://example.com', 'https://app.example.com:8443'],
    'otlpEndpoint': 'https://collector.example.com',
}
