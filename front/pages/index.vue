<template>
  <section class="container">
    <div>
      <h1 class="title">
        WebAuthn
      </h1>
      <div>
        <div class="forms">
          <label>username</label>
          <input type="text" v-model="username"/>
        </div>
        <div class="controls">
          <button class="attestation" @click="attestation">Regist</button>
          <button class="assertion" @click="assertion">Login</button>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
  export default {
    data() {
      return {
        username: 'TaroYamada'
      }
    },
    methods: {
      async attestation() {
        try {
          await this.$webauthn.attestation(this.username);
        } catch (e) {
          console.error(e.message);
          if (e.response && e.response.data) {
            console.error(e.response.data);
          }
        }
      },
      async assertion() {
        try {
          await this.$webauthn.assertion(this.username)
        } catch (e) {
          console.error(e.message);
          if (e.response && e.response.data) {
            console.error(e.response.data);
          }
        }
      }
    }
  }
</script>

<style scoped>
  /* Sample `apply` at-rules with Tailwind CSS
  .container {
    @apply min-h-screen flex justify-center items-center text-center mx-auto;
  }
  */
  .container {
    margin: 0 auto;
    min-height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
  }

  .title {
    font-family: 'Quicksand', 'Source Sans Pro', -apple-system, BlinkMacSystemFont,
    'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    display: block;
    font-weight: 300;
    font-size: 100px;
    color: #35495e;
    letter-spacing: 1px;
  }

  .subtitle {
    font-weight: 300;
    font-size: 42px;
    color: #526488;
    word-spacing: 5px;
    padding-bottom: 15px;
  }

  .links {
    padding-top: 15px;
  }

  .forms {
    margin: 10px;
  }

  input {
    border: 1px solid lightgray;
    padding: 5px;
  }

  button {
    border: 1px solid lightgray;
    border-radius: 10px;
    padding: 10px 30px;
  }

  button:hover {
    background-color: lightgray;
  }

  button:active {
    background-color: #b3b3b3;
  }


</style>
