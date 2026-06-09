<!doctype html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Absensi — Test UI</title>
    <style>
        :root { --bg: #f3f4f6; --card: #fff; --border: #e5e7eb; --primary: #2563eb; --muted: #6b7280; }
        body { font-family: system-ui, sans-serif; margin: 0; padding: 1.25rem; background: var(--bg); color: #111827; }
        h1 { font-size: 1.35rem; margin: 0 0 0.25rem; }
        .sub { color: var(--muted); font-size: 0.85rem; margin-bottom: 1rem; }
        .box { background: var(--card); padding: 1rem 1.1rem; border-radius: 10px; margin-bottom: 1rem; box-shadow: 0 1px 3px rgb(0 0 0 / 0.06); border: 1px solid var(--border); }
        h2 { font-size: 0.95rem; margin: 0 0 0.65rem; color: #374151; }
        label { display: block; font-size: 0.78rem; color: #4b5563; margin-top: 0.45rem; }
        input, select, textarea, button { width: 100%; max-width: 36rem; padding: 0.45rem 0.55rem; margin-top: 0.15rem; box-sizing: border-box; border: 1px solid var(--border); border-radius: 6px; font-size: 0.9rem; }
        button { cursor: pointer; background: var(--primary); color: #fff; border: none; font-weight: 600; margin-top: 0.5rem; }
        button.secondary { background: #6b7280; }
        button.ghost { background: #e5e7eb; color: #111827; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.65rem; max-width: 36rem; }
        .grid-3 { grid-template-columns: repeat(3, 1fr); }
        .row { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: center; margin-top: 0.5rem; }
        .row button { width: auto; margin-top: 0; }
        pre { background: #111827; color: #e5e7eb; padding: 1rem; border-radius: 8px; overflow-x: auto; min-height: 140px; font-size: 0.75rem; margin: 0; }
        [hidden] { display: none !important; }
        .badge { display: inline-block; padding: 0.2rem 0.55rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600; background: #dbeafe; color: #1e40af; }
        .badge.warn { background: #fef3c7; color: #92400e; }
        hr.sep { border: none; border-top: 1px solid var(--border); margin: 0.75rem 0; }
        .hint { font-size: 0.75rem; color: var(--muted); margin-top: 0.25rem; }
    </style>
</head>
<body>
    <h1 data-testid="page-title">Absensi — Test UI</h1>
    <p class="sub">Panel uji API (Sanctum). Token disimpan di <code>localStorage</code>. Ganti user lewat logout atau preset email.</p>

    <div class="box" data-testid="login-section">
        <h2>1) Login</h2>
        <div class="row">
            <button type="button" class="ghost" onclick="preset('admin@kampus.test')">Preset Admin</button>
            <button type="button" class="ghost" onclick="preset('dosen@kampus.test')">Preset Dosen</button>
            <button type="button" class="ghost" onclick="preset('mahasiswa@kampus.test')">Preset Mahasiswa</button>
        </div>
        <div class="grid">
            <div>
                <label>Email</label>
                <input id="email" data-testid="login-email" value="admin@kampus.test" autocomplete="username">
            </div>
            <div>
                <label>Password</label>
                <input id="password" data-testid="login-password" type="password" value="password123" autocomplete="current-password">
            </div>
        </div>
        <div class="row">
            <button type="button" data-testid="login-submit" onclick="login()">Login</button>
            <button type="button" class="secondary" onclick="logout()">Logout &amp; hapus token</button>
        </div>
        <p class="hint">Setelah login, panggil <strong>Muat profil</strong> atau gunakan aksi di bawah — token otomatis terpasang.</p>
        <div class="row">
            <span id="authState" class="badge warn" data-testid="auth-badge">Belum login</span>
            <button type="button" class="ghost" onclick="loadMe()">GET /api/me</button>
        </div>
    </div>

    <div class="box" id="panel-admin" hidden data-testid="panel-admin">
        <h2>Admin — data &amp; laporan</h2>
        <div class="row">
            <button type="button" onclick="callApi('GET','/api/admin/attendance-sessions')">GET sesi absensi</button>
            <button type="button" onclick="callApi('GET','/api/admin/attendance-records')">GET rekaman absensi</button>
        </div>
        <hr class="sep">
        <strong>Program studi</strong>
        <label>Nama prodi</label>
        <input id="adm_ps_nama" placeholder="Teknik Informatika" value="Prodi Uji">
        <button type="button" class="secondary" onclick="adminProgramStudi()">POST /api/admin/program-studi</button>
        <hr class="sep">
        <strong>Mata kuliah</strong>
        <div class="grid">
            <div><label>Kode MK</label><input id="adm_mk_kode" value="IF999"></div>
            <div><label>Nama MK</label><input id="adm_mk_nama" value="MK Uji"></div>
        </div>
        <div class="grid">
            <div><label>SKS</label><input id="adm_mk_sks" type="number" value="3" min="1"></div>
            <div><label>Prodi ID</label><input id="adm_mk_prodi" type="number" value="1" min="1"></div>
        </div>
        <button type="button" class="secondary" onclick="adminMk()">POST /api/admin/mata-kuliah</button>
        <hr class="sep">
        <strong>Kelas (assign dosen)</strong>
        <div class="hint">dosen_id = ID <em>user</em> dosen (bukan tabel dosens).</div>
        <div class="grid">
            <div><label>MK ID</label><input id="adm_kelas_mk" type="number" value="1"></div>
            <div><label>Dosen user ID</label><input id="adm_kelas_dosen" type="number" value="2"></div>
        </div>
        <div class="grid">
            <div><label>Kode kelas</label><input id="adm_kelas_kode" value="TI-3A"></div>
            <div><label>Nama kelas</label><input id="adm_kelas_nama" value="Algoritma 3A"></div>
        </div>
        <div class="grid">
            <div><label>Hari (1–7)</label><input id="adm_kelas_hari" type="number" value="3" min="1" max="7"></div>
            <div><label>Jam mulai / selesai</label><input id="adm_kelas_mulai" value="09:00"><input id="adm_kelas_selesai" value="10:40" style="margin-top:4px"></div>
        </div>
        <button type="button" class="secondary" onclick="adminKelas()">POST /api/admin/kelas</button>
        <hr class="sep">
        <strong>Enroll mahasiswa</strong>
        <div class="grid">
            <div><label>Kelas ID</label><input id="adm_en_kelas" type="number" value="1"></div>
            <div><label>Student user ID</label><input id="adm_en_mhs" type="number" value="3"></div>
        </div>
        <button type="button" class="secondary" onclick="adminEnroll()">POST /api/admin/enroll-mahasiswa</button>
            </div>

    <div class="box" id="panel-dosen" hidden data-testid="panel-dosen">
        <h2>Dosen — jadwal &amp; QR</h2>
        <div class="row">
            <button type="button" onclick="callApi('GET','/api/lecturer/schedules')">GET jadwal mengajar</button>
        </div>
        <hr class="sep">
        <strong>Buat sesi + generate QR</strong>
        <div class="grid">
            <div><label>Kelas ID</label><input id="dos_kelas" type="number" value="1"></div>
            <div><label>Schedule ID (opsional)</label><input id="dos_sched" type="number" placeholder="kosongkan jika tidak ada"></div>
        </div>
        <label>Start at (ISO / datetime lokal)</label>
        <input id="dos_start" value="">
        <div class="grid">
            <div><label>Lat kelas</label><input id="dos_lat" value="-6.2"></div>
            <div><label>Long kelas</label><input id="dos_lng" value="106.816666"></div>
        </div>
        <div class="grid">
            <div><label>Radius (m)</label><input id="dos_rad" type="number" value="80"></div>
            <div><label>QR valid (detik)</label><input id="dos_qrsec" type="number" value="120"></div>
        </div>
        <button type="button" onclick="dosenCreateSession()">POST /api/lecturer/sessions</button>
        <p class="hint">Token QR terakhir: <span id="lastQr" style="word-break:break-all;font-family:monospace">—</span></p>
        <hr class="sep">
        <strong>Sesi aktif (ID dari respons create)</strong>
        <div class="grid">
            <div><label>Sesi ID</label><input id="dos_sesi" type="number" placeholder="99"></div>
            <div><label>&nbsp;</label><span class="hint">Isi setelah create berhasil</span></div>
        </div>
        <div class="row">
            <button type="button" class="secondary" onclick="dosenRefreshQr()">POST refresh QR</button>
            <button type="button" class="secondary" onclick="dosenClose()">PATCH tutup sesi</button>
            <button type="button" class="secondary" onclick="dosenAttendances()">GET presensi sesi</button>
        </div>
    </div>

    <div class="box" id="panel-mahasiswa" hidden data-testid="panel-mahasiswa">
        <h2>Mahasiswa — kelas, histori, scan</h2>
        <div class="row">
            <button type="button" onclick="callApi('GET','/api/student/classes')">GET kelas saya</button>
            <button type="button" onclick="callApi('GET','/api/student/histories')">GET histori presensi</button>
        </div>
        <hr class="sep">
        <strong>Check-in (QR + GPS)</strong>
        <label>QR token</label>
        <textarea id="qrToken" data-testid="scan-token" rows="3" placeholder="Tempel token dari dosen (create / refresh session)"></textarea>
        <div class="grid">
            <div><label>Latitude</label><input id="lat" data-testid="scan-lat" value="-6.20000000"></div>
            <div><label>Longitude</label><input id="lng" data-testid="scan-lng" value="106.81666600"></div>
        </div>
        <div class="row">
            <button type="button" onclick="studentCheckin()">POST /api/student/checkin</button>
            <button type="button" class="ghost" onclick="setGpsNear()">GPS ~dekat titik demo</button>
            <button type="button" class="ghost" onclick="setGpsFar()">GPS ~jauh (uji tolak)</button>
        </div>
    </div>

    <div class="box">
        <h2>Output</h2>
        <pre id="output" data-testid="api-output"></pre>
    </div>

    <script>
        let token = localStorage.getItem('absensi_test_token') || '';
        let currentRole = null;

        function print(data) {
            const el = document.getElementById('output');
            el.textContent = typeof data === 'string' ? data : JSON.stringify(data, null, 2);
        }

        function authHeaders(json = true) {
            const h = { 'Accept': 'application/json' };
            if (json) h['Content-Type'] = 'application/json';
            if (token) h['Authorization'] = 'Bearer ' + token;
            return h;
        }

        function setAuthState(text, ok) {
            const el = document.getElementById('authState');
            el.textContent = text;
            el.className = 'badge ' + (ok ? '' : 'warn');
        }

        function showPanels(role) {
            currentRole = role;
            const r = role || '';
            document.getElementById('panel-admin').hidden = r !== 'admin';
            document.getElementById('panel-dosen').hidden = r !== 'dosen';
            document.getElementById('panel-mahasiswa').hidden = r !== 'mahasiswa';
        }

        function preset(email) {
            document.getElementById('email').value = email;
        }

        async function login() {
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const res = await fetch('/api/login', {
                method: 'POST',
                headers: authHeaders(),
                body: JSON.stringify({ email, password })
            });
            let data;
            try { data = await res.json(); } catch (_) { data = await res.text(); }
            token = (data && data.access_token) ? data.access_token : '';
            if (token) localStorage.setItem('absensi_test_token', token);
            print({ status: res.status, data });
            if (data && data.user && data.user.role) {
                setAuthState('Login: ' + data.user.role, true);
                showPanels(data.user.role);
            } else {
                setAuthState('Login gagal / tanpa role', false);
            }
        }

        function logout() {
            token = '';
            localStorage.removeItem('absensi_test_token');
            currentRole = null;
            showPanels(null);
            document.getElementById('panel-admin').hidden = true;
            document.getElementById('panel-dosen').hidden = true;
            document.getElementById('panel-mahasiswa').hidden = true;
            setAuthState('Belum login', false);
            print({ message: 'Token dihapus.' });
        }

        async function loadMe() {
            const res = await fetch('/api/me', { headers: authHeaders() });
            let data;
            try { data = await res.json(); } catch (_) { data = await res.text(); }
            print({ status: res.status, data });
            const u = data && data.user;
            if (u && u.role) {
                setAuthState('Role: ' + u.role, true);
                showPanels(u.role);
            }
        }

        async function callApi(method, path, body = null) {
            const res = await fetch(path, {
                method,
                headers: authHeaders(),
                ...(body ? { body: JSON.stringify(body) } : {})
            });
            let data;
            try { data = await res.json(); } catch (_) { data = await res.text(); }
            print({ status: res.status, data });
            return { res, data };
        }

        async function adminProgramStudi() {
            await callApi('POST', '/api/admin/program-studi', {
                nama_prodi: document.getElementById('adm_ps_nama').value
            });
        }
        async function adminMk() {
            await callApi('POST', '/api/admin/mata-kuliah', {
                kode_mk: document.getElementById('adm_mk_kode').value,
                nama_mk: document.getElementById('adm_mk_nama').value,
                sks: Number(document.getElementById('adm_mk_sks').value),
                prodi_id: Number(document.getElementById('adm_mk_prodi').value)
            });
        }
        async function adminKelas() {
            await callApi('POST', '/api/admin/kelas', {
                mk_id: Number(document.getElementById('adm_kelas_mk').value),
                dosen_id: Number(document.getElementById('adm_kelas_dosen').value),
                kode_kelas: document.getElementById('adm_kelas_kode').value,
                nama_kelas: document.getElementById('adm_kelas_nama').value,
                hari: Number(document.getElementById('adm_kelas_hari').value),
                jam_mulai: document.getElementById('adm_kelas_mulai').value,
                jam_selesai: document.getElementById('adm_kelas_selesai').value
            });
        }
        async function adminEnroll() {
            await callApi('POST', '/api/admin/enroll-mahasiswa', {
                kelas_id: Number(document.getElementById('adm_en_kelas').value),
                student_id: Number(document.getElementById('adm_en_mhs').value)
            });
        }
        
        function defaultStartAt() {
            const d = new Date();
            d.setMinutes(d.getMinutes() - 5);
            return d.toISOString().slice(0, 16);
        }

        document.getElementById('dos_start').value = defaultStartAt();

        async function dosenCreateSession() {
            const body = {
                kelas_id: Number(document.getElementById('dos_kelas').value),
                start_at: document.getElementById('dos_start').value ? new Date(document.getElementById('dos_start').value).toISOString() : new Date().toISOString(),
                lat_kelas: Number(document.getElementById('dos_lat').value),
                long_kelas: Number(document.getElementById('dos_lng').value),
                radius_kelas: Number(document.getElementById('dos_rad').value),
                qr_valid_seconds: Number(document.getElementById('dos_qrsec').value)
            };
            const sid = document.getElementById('dos_sched').value;
            if (sid) body.schedule_id = Number(sid);
            const { res, data } = await callApi('POST', '/api/lecturer/sessions', body);
            if (data && data.qr_token) {
                document.getElementById('lastQr').textContent = data.qr_token;
                document.getElementById('qrToken').value = data.qr_token;
                if (data.session && data.session.id) {
                    document.getElementById('dos_sesi').value = data.session.id;
                }
            }
        }

        async function dosenRefreshQr() {
            const id = document.getElementById('dos_sesi').value;
            if (!id) return print({ error: 'Isi sesi ID' });
            const sec = Number(document.getElementById('dos_qrsec').value) || 120;
            const { data } = await callApi('POST', '/api/lecturer/sessions/' + id + '/refresh-qr', { qr_valid_seconds: sec });
            if (data && data.qr_token) {
                document.getElementById('lastQr').textContent = data.qr_token;
                document.getElementById('qrToken').value = data.qr_token;
            }
        }

        async function dosenClose() {
            const id = document.getElementById('dos_sesi').value;
            if (!id) return print({ error: 'Isi sesi ID' });
            await callApi('PATCH', '/api/lecturer/sessions/' + id + '/close');
        }

        async function dosenAttendances() {
            const id = document.getElementById('dos_sesi').value;
            if (!id) return print({ error: 'Isi sesi ID' });
            await callApi('GET', '/api/lecturer/sessions/' + id + '/attendances');
        }

        async function studentCheckin() {
            const qr_token = document.getElementById('qrToken').value.trim();
            const latitude = Number(document.getElementById('lat').value);
            const longitude = Number(document.getElementById('lng').value);
            await callApi('POST', '/api/student/checkin', { qr_token, latitude, longitude, accuracy: 10 });
        }

        function setGpsNear() {
            document.getElementById('lat').value = '-6.199955';
            document.getElementById('lng').value = '106.816666';
        }
        function setGpsFar() {
            document.getElementById('lat').value = '-6.2045';
            document.getElementById('lng').value = '106.816666';
        }

        (async function init() {
            if (!token) return;
            setAuthState('Memuat profil…', true);
            try {
                const res = await fetch('/api/me', { headers: authHeaders() });
                const data = await res.json().catch(() => ({}));
                if (res.ok && data.user && data.user.role) {
                    setAuthState('Role: ' + data.user.role + ' (token tersimpan)', true);
                    showPanels(data.user.role);
                    print({ restored: true, user: data.user });
                } else {
                    setAuthState('Token tidak valid — login ulang', false);
                }
            } catch (e) {
                setAuthState('Gagal /api/me', false);
            }
        })();
    </script>
</body>
</html>
