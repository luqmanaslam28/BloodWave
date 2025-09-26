importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCc8H-V1JO-1gtbkgyTsuwf5IvLsNVnPNM",
  authDomain: "bloodwave-94715.firebaseapp.com",
  projectId: "bloodwave-94715",
  storageBucket: "bloodwave-94715.appspot.com",
  messagingSenderId: "610630473879",
  appId: "1:610630473879:web:5269ef8b04835eed94f1d2"
});

const messaging = firebase.messaging();
