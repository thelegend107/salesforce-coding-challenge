import displayAddress from "../displayAddress"

const addressObj = {
    id: 1,
    sf_id: '001ak00000CFPdYAAX',
    address1: '9376 E. Helen Ave.',
    address2: 'APT 202',
    city: 'East Haven',
    state: 'CT',
    country: 'USA',
    postalCode: '6512'
}

const addressObjNoState = {
    id: 1,
    sf_id: '001ak00000CFPdYAAX',
    address1: '9376 E. Helen Ave.',
    address2: '',
    city: 'East Haven',
    state: '',
    country: 'USA',
    postalCode: '6512'
}

const addressObjNoStateOrCity = {
    id: 1,
    sf_id: '001ak00000CFPdYAAX',
    address1: '9376 E. Helen Ave.',
    address2: '',
    city: '',
    state: '',
    country: 'USA',
    postalCode: '6512'
}

test("Can Parse Address object to string", () => {
    let addressString = displayAddress(addressObj)
    let addressArray = addressString.split(', ')

    expect(addressArray.length).toBe(4)
})

test("Can Parse Address object without state to string", () => {
    let addressString = displayAddress(addressObjNoState)
    let addressArray = addressString.split(', ')

    expect(addressArray.length).toBe(4)
})

test("Can Parse Address object without state or city to string", () => {
    let addressString = displayAddress(addressObjNoStateOrCity)
    let addressArray = addressString.split(', ')

    expect(addressArray.length).toBe(3)
})