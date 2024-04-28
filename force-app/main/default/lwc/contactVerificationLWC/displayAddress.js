export default function (obj) {
    let addressArray = []
    if (obj.address1 || obj.address2)
        addressArray.push(
            (
                (obj.address1 ? obj.address1 : '')
                + " " +
                (obj.address2 ? obj.address2 : '')
            ).trim()
        )
    if (obj.city || obj.state)
        addressArray.push(
            (
                (obj.city ? obj.city : '')
                + " " +
                (obj.state ? obj.state : '')
            ).trim()
        )
    if (obj.postalCode) addressArray.push(obj.postalCode)
    if (obj.country) addressArray.push(obj.country)

    return addressArray.join(", ");
}