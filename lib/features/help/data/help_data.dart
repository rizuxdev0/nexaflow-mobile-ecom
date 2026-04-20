import 'package:flutter/material.dart';
import '../models/help_item.dart';

final List<HelpSection> helpSections = [
  HelpSection(
    id: 'compte',
    icon: Icons.person_outline_rounded,
    title: 'Compte & Inscription',
    description: 'Créer, gérer et sécuriser votre compte',
    color: Colors.blue,
    faqs: [
      FAQItem(
        question: 'Comment créer un compte ?',
        answer: 'Rendez-vous sur la page "Connexion / Inscription" accessible depuis le menu ou l\'icône utilisateur en haut à droite. Remplissez le formulaire avec votre nom, email et mot de passe, puis cliquez sur "Créer un compte". Un email de confirmation pourra vous être envoyé.',
        tags: ['inscription', 'compte'],
      ),
      FAQItem(
        question: 'Comment me connecter ?',
        answer: 'Cliquez sur l\'icône utilisateur en haut à droite ou allez sur "Connexion". Entrez votre email et mot de passe puis validez. Vous serez redirigé vers votre espace client.',
        tags: ['connexion', 'login'],
      ),
      FAQItem(
        question: 'Comment modifier mes informations personnelles ?',
        answer: 'Connectez-vous à votre compte, puis accédez à "Mon compte". Vous pourrez y modifier votre nom, adresse email, numéro de téléphone et adresse de livraison.',
        tags: ['profil', 'informations'],
      ),
      FAQItem(
        question: 'J\'ai oublié mon mot de passe, que faire ?',
        answer: 'Sur la page de connexion, cliquez sur "Mot de passe oublié". Entrez votre adresse email et vous recevrez un lien de réinitialisation. Suivez les instructions dans l\'email pour créer un nouveau mot de passe.',
        tags: ['mot de passe', 'reset'],
      ),
      FAQItem(
        question: 'Comment supprimer mon compte ?',
        answer: 'Contactez notre service client par email ou téléphone pour demander la suppression de votre compte. Toutes vos données personnelles seront effacées conformément à notre politique de confidentialité.',
        tags: ['suppression', 'RGPD'],
      ),
    ],
  ),
  HelpSection(
    id: 'catalogue',
    icon: Icons.grid_view_rounded,
    title: 'Catalogue & Produits',
    description: 'Parcourir, rechercher et comparer les produits',
    color: Colors.teal,
    faqs: [
      FAQItem(
        question: 'Comment rechercher un produit ?',
        answer: 'Utilisez la barre de recherche en haut de la page (icône loupe). Tapez le nom, la catégorie ou une caractéristique du produit. Les résultats s\'affichent en temps réel pendant que vous tapez.',
        tags: ['recherche', 'produit'],
      ),
      FAQItem(
        question: 'Comment filtrer les produits ?',
        answer: 'Dans le catalogue, utilisez le bouton "Filtres" : catégorie, fourchette de prix, marque, disponibilité en stock, et attributs spécifiques.',
        tags: ['filtre', 'catalogue'],
      ),
      FAQItem(
        question: 'Comment trier les produits ?',
        answer: 'Un menu déroulant vous permet de trier par : pertinence, prix (croissant/décroissant), nouveautés ou meilleures ventes.',
        tags: ['tri', 'classement'],
      ),
      FAQItem(
        question: 'Les prix affichés incluent-ils la TVA ?',
        answer: 'Oui, les prix affichés incluent généralement la TVA (18%). Le détail est visible dans le panier et lors de la validation de la commande.',
        tags: ['prix', 'TVA', 'taxe'],
      ),
    ],
  ),
  HelpSection(
    id: 'panier',
    icon: Icons.shopping_cart_outlined,
    title: 'Panier & Commande',
    description: 'Ajouter au panier, passer commande',
    color: Colors.orange,
    faqs: [
      FAQItem(
        question: 'Comment ajouter un produit au panier ?',
        answer: 'Cliquez sur le bouton "Ajouter au panier" sur la fiche produit ou dans le catalogue. Vous pouvez modifier la quantité directement dans le panier.',
        tags: ['panier', 'ajout'],
      ),
      FAQItem(
        question: 'Comment modifier la quantité d\'un article ?',
        answer: 'Ouvrez le panier et utilisez les boutons + et - pour ajuster la quantité de chaque article.',
        tags: ['quantité', 'panier'],
      ),
      FAQItem(
        question: 'Comment supprimer un article du panier ?',
        answer: 'Dans le panier, cliquez sur l\'icône poubelle (🗑️) à côté de l\'article que vous souhaitez retirer.',
        tags: ['supprimer', 'panier'],
      ),
    ],
  ),
  HelpSection(
    id: 'paiement',
    icon: Icons.credit_card_rounded,
    title: 'Paiement',
    description: 'Modes de paiement acceptés et sécurité',
    color: Colors.purple,
    faqs: [
      FAQItem(
        question: 'Quels modes de paiement acceptez-vous ?',
        answer: 'Nous acceptons : les cartes bancaires (Visa, Mastercard), le paiement mobile (Mobile Money, Flooz, T-Money), le paiement à la livraison (COD), les virements et PayPal.',
        tags: ['paiement', 'méthode'],
      ),
      FAQItem(
        question: 'Le paiement est-il sécurisé ?',
        answer: 'Oui, tous les paiements en ligne sont sécurisés grâce au chiffrement SSL/TLS. Vos données bancaires ne sont jamais stockées sur nos serveurs.',
        tags: ['sécurité', 'paiement'],
      ),
      FAQItem(
        question: 'Comment appliquer un code promo ?',
        answer: 'Lors de la validation de la commande, vous trouverez un champ "Code promo". Saisissez votre code pour profiter de la réduction.',
        tags: ['promo', 'coupon'],
      ),
    ],
  ),
  HelpSection(
    id: 'livraison',
    icon: Icons.local_shipping_outlined,
    title: 'Livraison & Suivi',
    description: 'Zones, frais, délais et suivi de colis',
    color: Colors.cyan,
    faqs: [
      FAQItem(
        question: 'Quels sont les délais de livraison ?',
        answer: 'En général 1-3 jours ouvrés pour les zones urbaines, 3-7 jours pour les zones rurales ou éloignées.',
        tags: ['livraison', 'délai'],
      ),
      FAQItem(
        question: 'Comment suivre ma commande ?',
        answer: 'Depuis "Mon compte", accédez à "Mes commandes" pour voir le statut en temps réel (préparation, expédiée, livrée).',
        tags: ['suivi', 'tracking'],
      ),
    ],
  ),
  HelpSection(
    id: 'retours',
    icon: Icons.replay_circle_filled_rounded,
    title: 'Retours & Remboursements',
    description: 'Politique de retour, échange et remboursement',
    color: Colors.red,
    faqs: [
      FAQItem(
        question: 'Quelle est la politique de retour ?',
        answer: 'Vous disposez d\'un délai (14-30 jours après réception) pour retourner un article dans son état d\'origine.',
        tags: ['retour', 'politique'],
      ),
      FAQItem(
        question: 'Comment initier un retour ?',
        answer: 'Allez dans "Mes commandes", sélectionnez la commande et cliquez sur "Demander un retour".',
        tags: ['retour', 'procédure'],
      ),
      FAQItem(
        question: 'Quand serai-je remboursé ?',
        answer: 'Le remboursement est effectué dans un délai de 5-14 jours ouvrés après vérification du produit retourné.',
        tags: ['remboursement', 'délai'],
      ),
    ],
  ),
  HelpSection(
    id: 'favoris',
    icon: Icons.favorite_border_rounded,
    title: 'Favoris & Liste de souhaits',
    description: 'Sauvegarder et gérer vos produits préférés',
    color: Colors.pink,
    faqs: [
      FAQItem(
        question: 'Comment ajouter un produit aux favoris ?',
        answer: 'Survolez ou cliquez sur l\'icône cœur (♥) d\'un produit pour l\'ajouter à votre liste.',
        tags: ['favoris', 'cœur'],
      ),
      FAQItem(
        question: 'Où retrouver mes favoris ?',
        answer: 'Vos favoris sont accessibles depuis l\'onglet dédié dans la barre de navigation ou votre profil.',
        tags: ['favoris', 'liste'],
      ),
    ],
  ),
  HelpSection(
    id: 'fidelite',
    icon: Icons.stars_rounded,
    title: 'Programme de fidélité',
    description: 'Gagner et utiliser vos points fidélité',
    color: Colors.amber,
    faqs: [
      FAQItem(
        question: 'Comment fonctionne le programme ?',
        answer: 'Chaque achat vous rapporte des points. Ces points peuvent être convertis en réductions lors de vos prochains achats.',
        tags: ['fidélité', 'points'],
      ),
      FAQItem(
        question: 'Où voir mon solde de points ?',
        answer: 'Votre solde est visible dans votre profil sous la section "Fidélité".',
        tags: ['points', 'solde'],
      ),
    ],
  ),
  HelpSection(
    id: 'promos',
    icon: Icons.local_offer_outlined,
    title: 'Promotions & Offres',
    description: 'Offres spéciales et bons plans',
    color: Colors.lightGreen,
    faqs: [
      FAQItem(
        question: 'Où trouver les promotions ?',
        answer: 'Consultez la section "Promos" sur l\'accueil ou via le menu pour découvrir les ventes flash et offres du moment.',
        tags: ['promotions', 'offres'],
      ),
    ],
  ),
  HelpSection(
    id: 'securite',
    icon: Icons.shield_outlined,
    title: 'Sécurité & Confidentialité',
    description: 'Protection de vos données',
    color: Colors.blueGrey,
    faqs: [
      FAQItem(
        question: 'Mes données sont-elles protégées ?',
        answer: 'Oui, nous utilisons un cryptage SSL de pointe pour protéger vos informations personnelles et bancaires.',
        tags: ['données', 'sécurité'],
      ),
    ],
  ),
];

final List<GuideStep> guideSteps = [
  GuideStep(step: 1, icon: Icons.person_add_outlined, title: 'Créer votre compte', description: 'Inscrivez-vous gratuitement pour accéder aux favoris, historique et fidélité.'),
  GuideStep(step: 2, icon: Icons.search_rounded, title: 'Parcourir le catalogue', description: 'Explorez par catégorie ou utilisez la recherche pour trouver vos articles.'),
  GuideStep(step: 3, icon: Icons.favorite_border_rounded, title: 'Sauvegarder vos favoris', description: 'Likez les produits qui vous plaisent pour les retrouver plus tard.'),
  GuideStep(step: 4, icon: Icons.shopping_cart_checkout_rounded, title: 'Remplir votre panier', description: 'Ajoutez les produits et ajustez les quantités selon vos besoins.'),
  GuideStep(step: 5, icon: Icons.local_offer_outlined, title: 'Appliquer vos codes promo', description: 'Utilisez vos coupons lors de la validation pour réduire le total.'),
  GuideStep(step: 6, icon: Icons.receipt_long_outlined, title: 'Passer commande', description: 'Confirmez votre adresse et choisissez votre mode de paiement préféré.'),
  GuideStep(step: 7, icon: Icons.local_shipping_outlined, title: 'Suivre votre livraison', description: 'Suivez l\'état de votre commande en temps réel depuis votre espace client.'),
  GuideStep(step: 8, icon: Icons.star_outline_rounded, title: 'Laisser un avis', description: 'Partagez votre expérience pour aider les autres clients.'),
  GuideStep(step: 9, icon: Icons.workspace_premium_outlined, title: 'Gagner des points', description: 'Chaque achat augmente votre solde de points fidélité.'),
  GuideStep(step: 10, icon: Icons.card_giftcard_rounded, title: 'Profiter des avantages', description: 'Convertissez vos points en cadeaux ou réductions exclusives.'),
];
