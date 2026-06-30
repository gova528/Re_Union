/* =========================================================================
   script.js — GRT 2006-2007 Grand Reunion Tour (Public Site)
   ========================================================================= */

document.addEventListener('DOMContentLoaded', () => {
  initLoader();
  initBackground();
  initNav();
  initScrollAnimations();
  initCountdown();
  loadSettings();
  loadAnnouncements();
  loadStudents();
  loadGallery();
  initRsvpForm();
  initLightbox();
  initTilt();
});

/* ---------------- LOADER ---------------- */
function initLoader() {
  const loader = document.getElementById('loader');
  window.addEventListener('load', () => {
    setTimeout(() => loader && loader.classList.add('hidden'), 600);
  });
  // Fallback in case load event already fired
  setTimeout(() => loader && loader.classList.add('hidden'), 2500);
}

/* ---------------- THREE.JS PARTICLE BACKGROUND ---------------- */
function initBackground() {
  const canvas = document.getElementById('bg-canvas');
  if (!canvas || typeof THREE === 'undefined') return;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.z = 30;

  const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  const particleCount = 280;
  const positions = new Float32Array(particleCount * 3);
  for (let i = 0; i < particleCount; i++) {
    positions[i * 3] = (Math.random() - 0.5) * 80;
    positions[i * 3 + 1] = (Math.random() - 0.5) * 80;
    positions[i * 3 + 2] = (Math.random() - 0.5) * 60;
  }
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

  const material = new THREE.PointsMaterial({
    color: 0xd4af37,
    size: 0.28,
    transparent: true,
    opacity: 0.75,
  });
  const particles = new THREE.Points(geometry, material);
  scene.add(particles);

  let mouseX = 0, mouseY = 0;
  window.addEventListener('mousemove', (e) => {
    mouseX = (e.clientX / window.innerWidth - 0.5) * 2;
    mouseY = (e.clientY / window.innerHeight - 0.5) * 2;
  });

  function animate() {
    requestAnimationFrame(animate);
    particles.rotation.y += 0.0007;
    particles.rotation.x += 0.0002;
    camera.position.x += (mouseX * 3 - camera.position.x) * 0.02;
    camera.position.y += (-mouseY * 3 - camera.position.y) * 0.02;
    camera.lookAt(scene.position);
    renderer.render(scene, camera);
  }
  animate();

  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
}

/* ---------------- NAV ---------------- */
function initNav() {
  const toggle = document.getElementById('nav-toggle');
  const links = document.getElementById('nav-links');
  if (toggle && links) {
    toggle.addEventListener('click', () => links.classList.toggle('open'));
    links.querySelectorAll('a').forEach(a => a.addEventListener('click', () => links.classList.remove('open')));
  }
}

/* ---------------- SCROLL ANIMATIONS (GSAP) ---------------- */
function initScrollAnimations() {
  if (typeof gsap === 'undefined') return;
  if (gsap.registerPlugin && typeof ScrollTrigger !== 'undefined') {
    gsap.registerPlugin(ScrollTrigger);
    document.querySelectorAll('section').forEach((sec) => {
      gsap.from(sec.children, {
        opacity: 0,
        y: 40,
        duration: 0.9,
        stagger: 0.08,
        ease: 'power3.out',
        scrollTrigger: { trigger: sec, start: 'top 80%' },
      });
    });
  }
}

/* ---------------- TILT EFFECT FOR CARDS ---------------- */
function initTilt() {
  document.body.addEventListener('mousemove', (e) => {
    const card = e.target.closest('.tilt-card, .quick-card');
    if (!card) return;
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left - rect.width / 2;
    const y = e.clientY - rect.top - rect.height / 2;
    card.style.transform = `perspective(800px) rotateX(${(-y / 18)}deg) rotateY(${(x / 18)}deg) translateY(-4px)`;
  });
  document.body.addEventListener('mouseleave', (e) => {
    const card = e.target.closest && e.target.closest('.tilt-card, .quick-card');
    if (card) card.style.transform = '';
  }, true);
  document.querySelectorAll('.tilt-card, .quick-card').forEach(card => {
    card.addEventListener('mouseleave', () => card.style.transform = '');
  });
}

/* ---------------- COUNTDOWN ---------------- */
let countdownTarget = null;
function initCountdown() {
  setInterval(updateCountdown, 1000);
}
function updateCountdown() {
  if (!countdownTarget) return;
  const now = new Date().getTime();
  const distance = countdownTarget - now;
  const el = (id) => document.getElementById(id);
  if (distance <= 0) {
    ['cd-days', 'cd-hours', 'cd-mins', 'cd-secs'].forEach(id => { if (el(id)) el(id).textContent = '00'; });
    return;
  }
  const days = Math.floor(distance / (1000 * 60 * 60 * 24));
  const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const mins = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
  const secs = Math.floor((distance % (1000 * 60)) / 1000);
  if (el('cd-days')) el('cd-days').textContent = String(days).padStart(2, '0');
  if (el('cd-hours')) el('cd-hours').textContent = String(hours).padStart(2, '0');
  if (el('cd-mins')) el('cd-mins').textContent = String(mins).padStart(2, '0');
  if (el('cd-secs')) el('cd-secs').textContent = String(secs).padStart(2, '0');
}

/* ---------------- API HELPERS ---------------- */
async function apiGet(url) {
  const res = await fetch(url);
  return res.json();
}
async function apiPost(url, body) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return res.json();
}

/* ---------------- SETTINGS / HERO / INVITE / CONTACT ---------------- */
async function loadSettings() {
  const result = await apiGet('/api/settings');
  if (!result.success) return;
  const s = result.data;
  setText('hero-title-text', s.hero_title);
  setText('hero-subtitle-text', s.hero_subtitle);
  setText('invite-venue', s.event_venue);
  setText('invite-date', s.event_date ? new Date(s.event_date.replace(' ', 'T')).toDateString() : '');
  setText('contact-email', s.contact_email);
  setText('contact-phone', s.contact_phone);

  if (s.event_date) {
    countdownTarget = new Date(s.event_date.replace(' ', 'T')).getTime();
    updateCountdown();
  }
}
function setText(id, value) {
  const el = document.getElementById(id);
  if (el && value !== undefined && value !== null) el.textContent = value;
}

/* ---------------- ANNOUNCEMENTS ---------------- */
async function loadAnnouncements() {
  const result = await apiGet('/api/announcements');
  if (!result.success) return;
  const list = result.data;
  const container = document.getElementById('announcements-list');
  const latestContainer = document.getElementById('latest-announcement');

  if (container) {
    container.innerHTML = list.map(renderAnnouncementCard).join('') || '<p class="section-desc">No announcements yet.</p>';
    bindLikeButtons(container);
  }
  if (latestContainer && list.length) {
    latestContainer.innerHTML = renderAnnouncementCard(list[0]);
    bindLikeButtons(latestContainer);
  }
}

function renderAnnouncementCard(a) {
  const date = new Date(a.published_at.replace(' ', 'T')).toDateString();
  return `
    <div class="announcement-card glass">
      <h3>${a.title}</h3>
      <div class="announcement-meta">${date}</div>
      <p>${a.body}</p>
      <button class="like-btn" data-id="${a.id}">
        <span class="like-icon">&#9825;</span> <span class="like-count">${a.like_count}</span> Likes
      </button>
    </div>`;
}

function bindLikeButtons(scope) {
  scope.querySelectorAll('.like-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      const id = btn.dataset.id;
      const result = await apiPost(`/api/announcements/${id}/like`, {});
      if (result.success) {
        btn.classList.toggle('liked', result.liked_now);
        btn.querySelector('.like-count').textContent = result.like_count;
      }
    });
  });
}

/* ---------------- STUDENT DIRECTORY ---------------- */
let currentGenderFilter = '';
let currentLetterFilter = '';
let currentSearch = '';

async function loadStudents() {
  const container = document.getElementById('directory-grid');
  if (!container) return;
  const params = new URLSearchParams();
  if (currentGenderFilter) params.set('gender', currentGenderFilter);
  if (currentLetterFilter) params.set('letter', currentLetterFilter);
  if (currentSearch) params.set('search', currentSearch);
  const result = await apiGet('/api/students?' + params.toString());
  if (!result.success) return;
  container.innerHTML = result.data.map(renderStudentCard).join('') || '<p class="section-desc">No classmates found.</p>';

  const searchInput = document.getElementById('directory-search');
  if (searchInput && !searchInput.dataset.bound) {
    searchInput.dataset.bound = '1';
    searchInput.addEventListener('input', debounce(() => {
      currentSearch = searchInput.value.trim();
      loadStudents();
    }, 300));
  }
  const genderSelect = document.getElementById('directory-gender');
  if (genderSelect && !genderSelect.dataset.bound) {
    genderSelect.dataset.bound = '1';
    genderSelect.addEventListener('change', () => {
      currentGenderFilter = genderSelect.value;
      loadStudents();
    });
  }
  buildAlphaFilter();
}

function renderStudentCard(s) {
  return `
    <div class="student-card glass tilt-card">
      <img class="student-photo" src="/${s.photo_path}" alt="${s.full_name}" loading="lazy">
      <h4>${s.full_name}</h4>
      <div class="role">${s.occupation || ''} ${s.current_city ? '· ' + s.current_city : ''}</div>
      <p class="bio">${s.biography || ''}</p>
    </div>`;
}

function buildAlphaFilter() {
  const container = document.getElementById('alpha-filter');
  if (!container || container.dataset.built) return;
  container.dataset.built = '1';
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  container.innerHTML = `<button data-letter="">All</button>` + letters.map(l => `<button data-letter="${l}">${l}</button>`).join('');
  container.querySelectorAll('button').forEach(btn => {
    btn.addEventListener('click', () => {
      container.querySelectorAll('button').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentLetterFilter = btn.dataset.letter;
      loadStudents();
    });
  });
}

function debounce(fn, delay) {
  let t;
  return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), delay); };
}

/* ---------------- GALLERY ---------------- */
async function loadGallery() {
  const result = await apiGet('/api/photos');
  if (!result.success) return;
  const grid = document.getElementById('gallery-grid');
  const preview = document.getElementById('gallery-preview');
  if (grid) {
    grid.innerHTML = result.data.map(renderGalleryItem).join('');
    bindGalleryClicks(grid, result.data);
  }
  if (preview) {
    const subset = result.data.slice(0, 4);
    preview.innerHTML = subset.map(renderGalleryItem).join('');
    bindGalleryClicks(preview, subset);
  }
}
function renderGalleryItem(p) {
  return `
    <div class="gallery-item" data-src="/${p.file_path}" data-caption="${p.caption || ''}">
      <img src="/${p.file_path}" alt="${p.caption || ''}" loading="lazy">
      <div class="gallery-caption">${p.caption || ''}</div>
    </div>`;
}
function bindGalleryClicks(scope) {
  scope.querySelectorAll('.gallery-item').forEach(item => {
    item.addEventListener('click', () => {
      openLightbox(item.dataset.src, item.dataset.caption);
    });
  });
}

/* ---------------- LIGHTBOX ---------------- */
function initLightbox() {
  const closeBtn = document.getElementById('lightbox-close');
  const lightbox = document.getElementById('lightbox');
  if (closeBtn) closeBtn.addEventListener('click', closeLightbox);
  if (lightbox) lightbox.addEventListener('click', (e) => { if (e.target.id === 'lightbox') closeLightbox(); });
}
function openLightbox(src, caption) {
  const lightbox = document.getElementById('lightbox');
  if (!lightbox) return;
  document.getElementById('lightbox-img').src = src;
  document.getElementById('lightbox-caption').textContent = caption || '';
  lightbox.classList.add('active');
}
function closeLightbox() {
  const lightbox = document.getElementById('lightbox');
  if (lightbox) lightbox.classList.remove('active');
}

/* ---------------- RSVP FORM ---------------- */
function initRsvpForm() {
  const form = document.getElementById('rsvp-form');
  if (!form) return;
  let selectedResponse = '';

  form.querySelectorAll('.rsvp-option').forEach(opt => {
    opt.addEventListener('click', () => {
      form.querySelectorAll('.rsvp-option').forEach(o => o.classList.remove('selected'));
      opt.classList.add('selected');
      selectedResponse = opt.dataset.value;
    });
  });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const status = document.getElementById('rsvp-status');
    const payload = {
      full_name: form.full_name.value.trim(),
      email: form.email.value.trim(),
      phone: form.phone.value.trim(),
      response: selectedResponse,
      message: form.message.value.trim(),
    };
    if (!payload.full_name || !selectedResponse) {
      status.textContent = 'Please enter your name and choose a response.';
      status.className = 'form-status error';
      return;
    }
    const result = await apiPost('/api/rsvp', payload);
    if (result.success) {
      status.textContent = 'Thank you! Your RSVP has been received.';
      status.className = 'form-status success';
      form.reset();
      form.querySelectorAll('.rsvp-option').forEach(o => o.classList.remove('selected'));
      selectedResponse = '';
    } else {
      status.textContent = result.error || 'Something went wrong. Please try again.';
      status.className = 'form-status error';
    }
  });
}
