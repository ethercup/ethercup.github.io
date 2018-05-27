export default {
  data () {
    return {
        monthNames: ["January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
],
    }
  },
  methods: {
    getReadableDate(seconds) {
      var date = new Date(seconds*1000)
      return date.getDate() + " " + this.monthNames[date.getMonth()] + " " + date.getFullYear() + ", " + date.getHours() + ":" + ('0' + date.getMinutes()).slice(-2);
    },
    getShortAddress(address) {
      if (address != undefined && address.length > 5) {
        return address.substring(0,6) + "..." + address.substring(address.length-4)  
      }
    },
    getNetworkName (networkId) {
      switch (networkId) {
        case 1:
          return 'Main network'
        case 2:
          return 'Morden test network'
        case 3:
          return 'Ropsten test network'
        case 4:
          return 'Rinkeby test network'
        case 42:
          return 'Kovan test network'
        default:
          console.log('This is an unknown network.')
          return 'Unknown network'
      } 
    }
  }

}