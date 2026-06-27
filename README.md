# Calculatrice de Pourboire

Une application Flutter professionnelle permettant de calculer automatiquement le montant d'un pourboire à partir du montant d'une facture et d'un pourcentage choisi. L'application intègre une interface moderne (support Dark/Light mode) et enregistre l'historique complet des calculs dans le Cloud via Firebase Firestore.

## 🚀 Fonctionnalités principales

- **Calcul en temps réel** : Saisissez le montant et ajustez le pourcentage (0-100%) via un curseur ou un champ texte pour voir le total instantanément.
- **Support Multi-Devises** : Choisissez entre CFA, €, et $ pour vos calculs.
- **Thème Professionnel** : Mode clair et sombre (Dark Mode) intégrés avec une couleur d'accent (Ambre) très lisible.
- **Historique Cloud** : Tous vos calculs sont enregistrés automatiquement et de manière sécurisée dans Firebase Firestore.
- **Graphique Statistique** : L'écran d'historique propose un graphique en barres (généré avec `fl_chart`) des 10 derniers pourboires pour analyser vos tendances.
- **Gestion des historiques** : Supprimez les calculs d'un simple geste (Swipe-to-delete) avec un système de notifications animées par le haut (Top Toast).

## 🛠️ Stack Technique

- **Framework** : Flutter / Dart
- **Backend & Base de données** : Firebase, Cloud Firestore
- **Packages externes** :
  - `firebase_core` et `cloud_firestore` pour la persistance des données.
  - `fl_chart` pour le rendu graphique professionnel.
  - `intl` pour le formatage précis des nombres et des dates.

## ⚙️ Pré-requis et Installation

Pour compiler l'application sur votre environnement de développement :
1. Assurez-vous d'avoir installé [Flutter](https://docs.flutter.dev/get-started/install).
2. Configurez un projet [Firebase](https://console.firebase.google.com/) et activez **Cloud Firestore**.
3. Téléchargez le fichier de configuration `google-services.json` depuis Firebase et placez-le dans le dossier `android/app/`.
4. (Pour Windows) Vérifiez que le "Mode Développeur" de votre OS est activé pour autoriser les liens symboliques (symlinks).

Ensuite, lancez la commande suivante dans le terminal :
```bash
flutter pub get
flutter run
```

---
*Ce projet a été développé dans le cadre d'un TP d'évaluation (Développement mobile).*
