# 📝 Customization Guide - Before Pushing to GitHub

This guide shows you **exactly where** to make changes before pushing to GitHub.

---

## 🔍 Files to Customize

### 1. `.github/ISSUE_TEMPLATE/config.yml`

**Location**: `.github/ISSUE_TEMPLATE/config.yml`  
**Lines to change**: 4, 7, 10

**Replace**:
```yaml
url: https://github.com/yourusername/chatur_frontend/discussions
url: https://github.com/yourusername/chatur_frontend#readme
url: https://github.com/yourusername/chatur_frontend/security
```

**With your actual GitHub username**:
```yaml
url: https://github.com/YOUR_GITHUB_USERNAME/chatur_frontend/discussions
url: https://github.com/YOUR_GITHUB_USERNAME/chatur_frontend#readme
url: https://github.com/YOUR_GITHUB_USERNAME/chatur_frontend/security
```

**Example** (if your username is `john-doe`):
```yaml
url: https://github.com/john-doe/chatur_frontend/discussions
url: https://github.com/john-doe/chatur_frontend#readme
url: https://github.com/john-doe/chatur_frontend/security
```

---

### 2. `README.md`

#### A. Clone URL (Line ~101)

**Find**:
```markdown
git clone https://github.com/yourusername/chatur_frontend.git
```

**Replace with**:
```markdown
git clone https://github.com/YOUR_GITHUB_USERNAME/chatur_frontend.git
```

#### B. Author Section (Line ~286)

**Find**:
```markdown
## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)
```

**Replace with** (Single author):
```markdown
## 👥 Authors

- **Your Full Name** - *Initial work* - [YourGitHub](https://github.com/YOUR_GITHUB_USERNAME)
```

**OR Replace with** (Team - **RECOMMENDED if you have teammates**):
```markdown
## 👥 Authors

- **Your Full Name** - *Lead Developer* - [YourGitHub](https://github.com/YOUR_GITHUB_USERNAME)
- **Teammate 1 Name** - *Backend Developer* - [Teammate1GitHub](https://github.com/TEAMMATE1_USERNAME)
- **Teammate 2 Name** - *UI/UX Designer* - [Teammate2GitHub](https://github.com/TEAMMATE2_USERNAME)
- **Teammate 3 Name** - *Contributor* - [Teammate3GitHub](https://github.com/TEAMMATE3_USERNAME)
```

**Example**:
```markdown
## 👥 Authors

- **John Doe** - *Lead Developer* - [johndoe](https://github.com/johndoe)
- **Jane Smith** - *Backend Developer* - [janesmith](https://github.com/janesmith)
- **Bob Johnson** - *UI/UX Designer* - [bobjohnson](https://github.com/bobjohnson)
```

#### C. Support Email (Line ~301)

**Find**:
```markdown
For support, email your-email@example.com or open an issue in the repository.
```

**Replace with**:
```markdown
For support, email support@yourdomain.com or open an issue in the repository.
```

**OR** (if you don't have a domain):
```markdown
For support, email yourname@gmail.com or open an issue in the repository.
```

---

### 3. `SECURITY.md`

#### A. Security Email (Line 21)

**Find**:
```markdown
Send an email to: **security@chatur-app.com** (replace with your actual email)
```

**Replace with**:
```markdown
Send an email to: **security@yourdomain.com**
```

**OR** (if you don't have a domain):
```markdown
Send an email to: **yourname.security@gmail.com**
```

#### B. Security Email at Bottom (Line 134)

**Find**:
```markdown
**Email**: security@chatur-app.com
```

**Replace with**:
```markdown
**Email**: security@yourdomain.com
```

**OR**:
```markdown
**Email**: yourname.security@gmail.com
```

---

### 4. `SETUP.md`

**Location**: `SETUP.md`  
**Line**: ~35

**Find**:
```markdown
git clone https://github.com/yourusername/chatur_frontend.git
```

**Replace with**:
```markdown
git clone https://github.com/YOUR_GITHUB_USERNAME/chatur_frontend.git
```

---

### 5. `CONTRIBUTING.md`

**Location**: `CONTRIBUTING.md`  
**Line**: ~48

**Find**:
```markdown
git clone https://github.com/yourusername/chatur_frontend.git
```

**Replace with**:
```markdown
git clone https://github.com/YOUR_GITHUB_USERNAME/chatur_frontend.git
```

---

## ✅ Should You Include Teammates?

### **YES, if:**
- ✅ You worked on this project with other people
- ✅ They contributed code, design, or ideas
- ✅ You want to give them credit
- ✅ It's a team project

### **How to Include Teammates:**

1. **In README.md Authors Section** (as shown above)
2. **In LICENSE** - Update copyright if it's a team project:
   ```markdown
   Copyright (c) 2024 Chatur Frontend Team
   ```
   OR
   ```markdown
   Copyright (c) 2024 Your Name, Teammate 1, Teammate 2
   ```

3. **In CONTRIBUTING.md** - You can add a "Team" section:
   ```markdown
   ## 👥 Team
   
   - **Your Name** - Lead Developer
   - **Teammate 1** - Backend Developer
   - **Teammate 2** - UI/UX Designer
   ```

---

## 📸 Optional: Add Screenshots

### Location: `README.md` (around line 200-210)

**Find this section**:
```markdown
## 📱 Screenshots

> Add screenshots of your app here
```

**Replace with**:
```markdown
## 📱 Screenshots

<div align="center">

### Home Screen
<img src="screenshots/home_screen.png" width="250" alt="Home Screen">

### Schemes Module
<img src="screenshots/schemes.png" width="250" alt="Schemes">

### Skills Marketplace
<img src="screenshots/skills.png" width="250" alt="Skills">

### Store
<img src="screenshots/store.png" width="250" alt="Store">

</div>
```

**Steps to add screenshots:**
1. Create a `screenshots/` folder in your project root
2. Add your app screenshots (PNG format, recommended size: 250x500px)
3. Name them: `home_screen.png`, `schemes.png`, `skills.png`, `store.png`, etc.
4. Update the README with your actual screenshot names

**OR** use a simpler format:
```markdown
## 📱 Screenshots

![Home Screen](screenshots/home.png) | ![Schemes](screenshots/schemes.png) | ![Skills](screenshots/skills.png)
:---:|:---:|:---:
Home Dashboard | Government Schemes | Skills Marketplace
```

---

## 🎯 Quick Checklist

Before pushing, make sure you've updated:

- [ ] `.github/ISSUE_TEMPLATE/config.yml` - GitHub username (3 places)
- [ ] `README.md` - Clone URL, Author section, Support email
- [ ] `SECURITY.md` - Security email (2 places)
- [ ] `SETUP.md` - Clone URL
- [ ] `CONTRIBUTING.md` - Clone URL
- [ ] `README.md` - Added teammates (if applicable)
- [ ] `README.md` - Added screenshots (optional)
- [ ] `LICENSE` - Updated copyright (if team project)

---

## 🚀 After Customization

Once you've made all changes:

```bash
# Check what changed
git status

# Review your changes
git diff

# Add all files
git add .

# Commit
git commit -m "docs: Customize documentation with project details"

# Push
git push origin main
```

---

## 💡 Tips

1. **GitHub Username**: Find it at the top-right of GitHub when logged in
2. **Email**: Use a professional email or create a dedicated one for the project
3. **Teammates**: Ask them for their GitHub usernames before adding
4. **Screenshots**: Take screenshots from a real device for best quality
5. **Test Links**: After pushing, test all GitHub links to make sure they work

---

**Need help?** Open an issue or check the documentation!

